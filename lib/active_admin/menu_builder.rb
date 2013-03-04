module ActiveAdmin

  class MenuBuilder

    def self.build_for_namespace(namespace)
      new(namespace).menu
    end

    attr_reader :menu

    def initialize(namespace)
      @namespace = namespace
    end

    def menu
      @menu ||= build_menu
    end

    private

    def namespace
      @namespace
    end

    def build_menu
      menu = Menu.new

      Dashboards.add_to_menu(namespace, menu)

      namespace.resources.each do |resource|
        register_with_menu(menu, resource) if resource.include_in_menu?
      end

      menu
    end

    # Does all the work of registernig a config with the menu system
    def register_with_menu(menu, resource)
      # The menu we're going to add this resource to
      add_to = menu

      # Adding as a child
      if resource.parent_menu_item
        parent = MenuItem.new resource.parent_menu_item
        add_to.add parent unless menu[parent.id] # Create the parent if it doesn't exist
        add_to = menu[parent.id]                 # Scope the code below to nest child inside
      end

      if add_to[resource.menu_item.id]
        existing = add_to[resource.menu_item.id]
        add_to.children.delete(existing)
        add_to.add(resource.menu_item)
        resource.menu_item.add(*existing.children)
      else
        add_to.add resource.menu_item
      end
    end

  end

end
