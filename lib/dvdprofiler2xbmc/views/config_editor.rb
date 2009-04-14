# require 'highline'
require "highline/import"

# monkey patch HighLine to get rid of the ugly message:
#  Your answer isn't valid (must match #<Proc:0xb76cb378@/home/royw/views/dvdprofiler2xbmc/lib/dvdprofiler2xbmc/app_config.rb:180>)
# basically the problem is with inspecting a lambda validator, so just don't do it...
class HighLine
  class Question
    def build_responses(  )
      append_default unless default.nil?
      @responses = { :ambiguous_completion =>
                       "Ambiguous choice.  " +
                       "Please choose one of #{@answer_type.inspect}.",
                     :ask_on_error         =>
                       "?  ",
                     :invalid_type         =>
                       "You must enter a valid #{@answer_type}.",
                     :no_completion        =>
                       "You must choose one of " +
                       "#{@answer_type.inspect}.",
                     :not_in_range         =>
                       "Your answer isn't within the expected range " +
                       "(#{expected_range}).",
                     :not_valid            =>
                       "Your answer isn't valid " +
                       (@validate.kind_of?(Proc) ?
                       '' : "(must match #{@validate.inspect}).")
                   }.merge(@responses)
    end
  end
end

class ConfigEditor

  def initialize
  end

  def execute
    @saved_interrupt_message = DvdProfiler2Xbmc.interrupt_message
    DvdProfiler2Xbmc.interrupt_message = ''
    report_invalid_config_items
    begin
      AppConfig[:logger].info('Configuration Editor')

      fields = AppConfig.navigation.collect do |page|
        page.values.flatten.select do|field|
          AppConfig.data_type[field]
        end
      end.flatten.uniq.compact
      while(field = menu_select('field', fields))
        begin
          edit_field(field)
        rescue
        end
      end
      if agree("Save? yes/no") {|q| q.default = 'yes'}
        AppConfig.save
      end
    rescue
    end
    DvdProfiler2Xbmc.interrupt_message = @saved_interrupt_message
  end

  def report_invalid_config_items
    buf = []
    AppConfig.validate.each do |field, value|
      unless AppConfig.validate[field].call(AppConfig.config[field])
        buf << field
      end
    end
    unless buf.empty?
      say 'The following config items are not valid and need to be changed:'
      buf.each {|line| say "  #{line}"}
    end
  end

  def edit_field(field)
    result = true
    while(result)
      field_header(field)

      choose do |menu|
        menu.prompt = "Please select: "
        menu.index = :number
        menu.index_suffix = ') '
        menu.choice(:quit, 'Quit') {result = false}
        case AppConfig.data_type[field]
        when :BOOLEAN
          menu.choice(:true, 'True') {AppConfig.config[field] = true}
          menu.choice(:false, 'False') {AppConfig.config[field] = false}
        else
          menu.choice(:default, 'Default') {AppConfig.config[field] = AppConfig.initial[field]}
          if AppConfig.data_type[field].to_s =~ /^ARRAY/
            menu.choice(:add, 'Add') {array_add(field)}
            menu.choice(:delete, 'Delete') {array_delete(field)}
          elsif AppConfig.data_type[field].to_s =~ /^HASH/
            menu.choice(:add, 'Add') {hash_add(field)}
            menu.choice(:delete, 'Delete') {hash_delete(field)}
          else
            menu.choice(:edit, 'Edit') {object_edit(field)}
          end
        end
      end
    end
    result
  end

  def field_header(field)
    say "\n"
    say "-------------------------------"
    say field
    say "\n"
    say AppConfig.help[field]
    say "\n"
    say "Default:"
    say prettify(AppConfig.initial[field])
    say "\n"
    say "Current:"
    say prettify(AppConfig.config[field])
    say "\n"
  end

  def object_edit(field)
    value = data_type_editor(field, AppConfig.data_type[field], AppConfig.initial[field])
    AppConfig.config[field] = value unless value.nil?
  end

  def hash_add(field)
    value = data_type_editor(field, AppConfig.data_type[field], AppConfig.initial[field])
    if value =~ /([^,]+)\s*,\s*(\S.*)/
      AppConfig.config[field][$1.strip] = $2.strip
    end
  end

  def hash_delete(field)
    choose do |menu|
      menu.prompt = "Please select to remove: "
      menu.index = :number
      menu.index_suffix = ') '
      menu.choice(:quit, 'Quit') {result = false}
      values = []
      AppConfig.config[field].each do |key, value|
        values << "#{key} => #{value}"
      end
      menu.choices(*values) do |value, details|
        if value =~ /(.*\S)\s+=>/
          AppConfig.config[field].delete($1)
        end
      end
    end
  end

  def array_add(field)
    value = data_type_editor(field, AppConfig.data_type[field], AppConfig.initial[field])
    AppConfig.config[field] += [value].flatten unless value.nil?
    AppConfig.config[field].uniq!
  end

  def array_delete(field)
    choose do |menu|
      menu.prompt = "Please select to remove: "
      menu.index = :number
      menu.index_suffix = ') '
      menu.choice(:quit, 'Quit') {result = false}
      menu.choices(*AppConfig.config[field]) do |extension, details|
        AppConfig.config[field].delete(extension)
      end
    end
  end

  def prettify(obj)
    str = obj.pretty_inspect
    if obj.kind_of? Mash
      str = obj.to_hash.pretty_inspect
    end
    if obj.kind_of? Array
      str = obj.inspect
    end
    if obj.kind_of? Hash
      key_length = 0
      obj.keys.each do |key|
        key_length = key.length if key.length > key_length
      end
      buf = []
      obj.each do |key,value|
        buf << sprintf("%-#{key_length}.#{key_length}s => %s", key, value)
      end
      str = buf.join("\n")
    end
    str
  end

  def data_type_editor(field, data_type, default_value=nil)
    value = nil
    case data_type
    when :BOOLEAN
      value = agree("Set #{field} to true: ") do |q|
        q.default = (default_value ? 'yes' : 'no') unless default_value.nil?
      end
    when :FILESPEC
      value = ask('New filespec: ') do |q|
#         q.answer_type = File
        q.validate = AppConfig.validate_item[field] unless AppConfig.validate_item[field].nil?
        q.confirm = false
        q.default = default_value unless default_value.nil?
      end
    when :PATHSPEC
      value = ask('New pathspec: ') do |q|
#         q.answer_type = Pathname
#         q.validate = lambda { |v| File.exist?(v) && File.directory?(v) }
        q.validate = AppConfig.validate_item[field] unless AppConfig.validate_item[field].nil?
        q.confirm = false
        q.default = default_value unless default_value.nil?
      end
    when :PERMISSIONS
      value = ask('New value (octal): ') do |q|
#         q.validate = lambda { |v| (v.to_i(8) >= 0) && (v.to_i(8) <= 07777) }
        q.validate = AppConfig.validate_item[field] unless AppConfig.validate_item[field].nil?
        q.default = default_value unless default_value.nil?
      end
    when :ARRAY_OF_STRINGS
      value = ask('New values or a blank line to quit: ') do |q|
        q.gather = ''
        q.validate = AppConfig.validate_item[field] unless AppConfig.validate_item[field].nil?
        # note, can not have both gather and default as there is no way to
        # terminate the input loop
      end
    when :ARRAY_OF_PATHSPECS
      # note, can not have both gather and default as there is no way to
      # terminate the input loop
      value = ask('New pathspecs or a blank line to quit: ') do |q|
        q.gather = ''
#         q.validate = lambda { |v| v.empty? || (File.exist?(v) && File.directory?(v)) }
        q.validate = AppConfig.validate_item[field] unless AppConfig.validate_item[field].nil?
      end
    when :HASH_FIXED_SYMBOL_KEYS_STRING_VALUES
    when :HASH_STRING_KEYS_STRING_VALUES
      value = ask('New value as key,value: ') do |q|
#         q.default = default_value unless default_value.nil?
      end
    else
      value = ask('New value: ')
    end
    value
  end

  VALUE_LENGTH = 60

  def menu_select(name, values)
    result = false
    say("\n#{name.capitalize} Selection")
    choose do |menu|
      menu.prompt = "Please select #{name}: "
      menu.index = :number
      menu.index_suffix = ') '
      menu.choice(:quit, 'Quit') {result = false}
      menu.choices(*(values.collect{|v| field_name_choice(v)})) do |command, details|
        result = command.split(" ").first
      end
    end
    result
  end

  def field_name_choice(value)
    value_str = sprintf("%-#{VALUE_LENGTH}.#{VALUE_LENGTH}s", first_line(value))
    if AppConfig.config[:color_enabled]
      color = 'green'
      unless AppConfig.validate[value].nil?
        color = 'red' unless AppConfig.validate[value].call(AppConfig.config[value])
      end
      value_str = "<%= color('#{value_str}', :#{color})%>"
    end
    str = sprintf("%20s  %s", value, value_str)
    str
  end

  def first_line(value)
    config_value = AppConfig.config[value]
    if config_value.kind_of? Mash
      config_value = config_value.to_hash
    end
    str = [config_value.inspect].flatten.first.split("\n").first
    if str.length > VALUE_LENGTH
      str = str[0..(VALUE_LENGTH - 4)] + '...'
    end
    str
  end

end