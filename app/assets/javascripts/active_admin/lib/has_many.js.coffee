class ActiveAdmin.HasMany
  constructor: (@options, @container)->
    defaults = {}
    @options = $.extend defaults, options
    @_init()
    @_bind()


  _init: ->
    if not @container
      throw new Error('Container element not found')
    else
      @$container = $(@container)

    if not @$container.find('a.button.has_many_add').length
      throw new Error('"has many add" button not found')
    else
      @add_has_many_add = @$container.find 'a.button.has_many_add'


  _bind: ->
    that = this
    # Provides a before-removal hook:
    # $ ->
    #   # This is a good place to tear down JS plugins to prevent memory leaks.
    #   $(document).on 'has_many_remove:before', '.has_many_container', (e, fieldset)->
    #     fieldset.find('.select2').select2 'destroy'
    #
    @$container.on 'click', 'a.button.has_many_remove', (e)->
      e.preventDefault()
      parent    = $(@).closest '.has_many_container'
      to_remove = $(@).closest 'fieldset'
      that._recompute_positions parent

      parent.trigger 'has_many_remove:before', [ to_remove ]
      to_remove.remove()

    # Provides before and after creation hooks:
    # $ ->
    #   # The before hook allows you to prevent the creation of new records.
    #   $(document).on 'has_many_add:before', '.has_many_container', (e)->
    #     if $(@).children('fieldset').length >= 3
    #       alert "you've reached the maximum number of items"
    #       e.preventDefault()
    #
    #   # The after hook is a good place to initialize JS plugins and the like.
    #   $(document).on 'has_many_add:after', '.has_many_container', (e, fieldset)->
    #     fieldset.find('select').chosen()
    #
    @$container.on 'click', 'a.button.has_many_add', (e)->
      e.preventDefault()
      elem   = $(@)
      parent = elem.closest '.has_many_container'
      parent.trigger before_add = $.Event 'has_many_add:before'

      unless before_add.isDefaultPrevented()
        index = parent.data('has_many_index') || parent.children('fieldset').length - 1
        parent.data has_many_index: ++index

        regex = new RegExp elem.data('placeholder'), 'g'
        html  = elem.data('html').replace regex, index

        fieldset = $(html).insertBefore(@)
        console.log("about to call")
        that._recompute_positions parent
        parent.trigger 'has_many_add:after', [ fieldset ]

    $(document).on 'change','.has_many_container[data-sortable] :input[name$="[_destroy]"]', ->
    that._recompute_positions $(@).closest '.has_many'

    @_init_sortable()

    $(document).on 'has_many_add:after', '.has_many_container', @_init_sortable


  # Helpers
  _init_sortable: ->
    elems = $('.has_many_container[data-sortable]:not(.ui-sortable)')
    elems.sortable \
      items: '> fieldset',
      handle: '> ol > .handle',
      stop:    @_recompute_positions()
    elems.each @_recompute_positions()

  _recompute_positions: (parent) ->
    parent     = if parent instanceof jQuery then parent else $(@)
    input_name = parent.data 'sortable'
    position   = 0

    parent.children('fieldset').each ->
      fieldset = $(@)
      # when looking for inputs, we ignore inputs from the possibly nested inputs
      # so, when defining your has_many, make sure to keep the sortable input at the root of the has_many block
      destroy_input  = fieldset.find "> ol > .input > :input[name$='[_destroy]']"
      sortable_input = fieldset.find "> ol > .input > :input[name$='[#{input_name}]']"

      if sortable_input.length
        sortable_input.val if destroy_input.is ':checked' then '' else position++

$.widget.bridge 'aaHasManyButtons', ActiveAdmin.HasMany

$ ->
  $(".has_many_container").aaHasManyButtons()