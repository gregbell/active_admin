require 'formtastic'

module ActiveAdmin
  class FormBuilder < ::Formtastic::SemanticFormBuilder

    attr_reader :form_buffers
    
    def initialize(*args)
      @form_buffers = ["".html_safe]
      super
    end

    def inputs(*args, &block)
      # Store that we are creating inputs without a block
      @inputs_with_block = block_given? ? true : false
      content = with_new_form_buffer { super }
      form_buffers.last << content.html_safe
    end

    # The input method returns a properly formatted string for
    # its contents, so we want to skip the internal buffering
    # while building up its contents
    def input(*args)
      if !polymorphic_attribute(args.first) || @inputs_with_block #ignore polymorphic attributes in default view
        content = with_new_form_buffer { super }
        return content.html_safe unless @inputs_with_block
        form_buffers.last << content.html_safe
      end
    end

    # The buttons method always needs to be wrapped in a new buffer
    def buttons(*args, &block)
      content = with_new_form_buffer do
        block_given? ? super : super { commit_button_with_cancel_link }
      end
      form_buffers.last << content.html_safe
    end

    def commit_button(*args)
      content = with_new_form_buffer{ super }
      form_buffers.last << content.html_safe
    end
    
    def cancel_link(url = nil, html_options = {}, li_attributes = {})
      li_attributes[:class] ||= "cancel"
      url ||= {:action => "index"}
      template.content_tag(:li, (template.link_to ActiveAdmin::Iconic.icon(:x) + " Cancel", url, html_options), li_attributes)
    end
    
    def commit_button_with_cancel_link
      content = commit_button
      content << cancel_link
    end
    
    def datepicker_input(method, options)
      options = options.dup
      options[:input_html] ||= {}
      options[:input_html][:class] = [options[:input_html][:class], "datepicker"].compact.join(' ')
      options[:input_html][:size] ||= "10"
      string_input(method, options)
    end

    def has_many(association, options = {}, &block)
      options = { :for => association }.merge(options)
      options[:class] ||= ""
      options[:class] << "inputs has_many_fields"

      # Add Delete Links
      form_block = proc do |has_many_form|
        block.call(has_many_form) + if has_many_form.object.new_record?
                                      template.content_tag :li do
                                        template.link_to "Delete", "#", :onclick => "$(this).closest('.has_many_fields').remove(); return false;", :class => "button"
                                      end
                                    else
                                    end
      end

      content = with_new_form_buffer do
        template.content_tag :div, :class => "has_many #{association}" do
          form_buffers.last << template.content_tag(:h3, association.to_s.titlecase)
          inputs options, &form_block

          # Capture the ADD JS
          js = with_new_form_buffer do
            inputs_for_nested_attributes  :for => [association, object.class.reflect_on_association(association).klass.new],
                                          :class => "inputs has_many_fields",
                                          :for_options => {
                                            :child_index => "NEW_RECORD"
                                          }, &form_block
          end

          js = template.escape_javascript(js)
          js = template.link_to "Add New #{association.to_s.singularize.titlecase}", "#", :onclick => "$(this).before('#{js}'.replace(/NEW_RECORD/g, new Date().getTime())); return false;", :class => "button"

          form_buffers.last << js.html_safe
        end
      end
      form_buffers.last << content.html_safe
    end

    private

    def with_new_form_buffer
      form_buffers << "".html_safe
      return_value = yield
      form_buffers.pop
      return_value
    end
    
    def polymorphic_attribute(attribute)
      polymorpic_attributes = Array.new
      polymorphic_associations = @object.class.reflect_on_all_associations.find_all{|e| e.options[:polymorphic]==true}
      polymorphic_associations ||= []
      polymorphic_associations.each{|p| polymorpic_attributes.push(p.name, p.options[:foreign_type].to_sym)}
      polymorpic_attributes.include?(attribute)
    end
  end
end
