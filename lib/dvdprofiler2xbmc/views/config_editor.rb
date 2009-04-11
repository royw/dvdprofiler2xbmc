# require 'highline'
require "highline/import"

class ConfigEditor

  def initialize
  end

  def execute
    AppConfig[:logger].info('Configuration Editor')

    fields = AppConfig.navigation.collect do |page|
      page.values.flatten.select do|field|
        AppConfig.data_type[field]
      end
    end.flatten.uniq.compact
    pp fields
    while(field = menu_select('field', fields))
      edit_field(field)
    end
  end

  def edit_field(field)
    result = true
    while(result)
      say field
      say AppConfig.help[field]
      say "Default:"
      say AppConfig.initial[field].pretty_inspect
      say "Current:"
      say AppConfig.config[field].pretty_inspect
      say "Data Type:  " + AppConfig.data_type[field].to_s

      choose do |menu|
        menu.prompt = "Please select: "
        menu.index = :number
        menu.index_suffix = ') '
        menu.choice(:quit, 'Quit') {result = false}
        menu.choice(:default, 'Default') {AppConfig.config[field] = AppConfig.initial[field]}
        menu.choice(:edit, 'Edit') do
          AppConfig.config[field] = ask('New value: ')
        end
      end
    end
    result
  end

  def menu_select(name, values)
    result = false
    say("\n#{name.capitalize} Selection")
    choose do |menu|
      menu.prompt = "Please select #{name}"
      menu.index = :number
      menu.index_suffix = ') '
      menu.choice(:quit, 'Quit') {result = false}
      menu.choices(*values) do |command, details|
        result = command
      end
    end
    result
  end

end
