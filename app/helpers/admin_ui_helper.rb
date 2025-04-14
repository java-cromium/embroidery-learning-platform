module AdminUiHelper
  def nav_item_visible?(resource, action = :view)
    can_access?(resource, action)
  end

  def action_button(text, path, options = {})
    resource = options.delete(:resource)
    action = options.delete(:action) || :view
    html_options = {
      class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white " +
             "#{options[:disabled] ? 'bg-gray-400 cursor-not-allowed' : 'bg-pink-600 hover:bg-pink-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500'}"
    }.merge(options)

    if resource && action && !can_access?(resource, action)
      html_options[:disabled] = true
      html_options[:class] = html_options[:class].sub('bg-pink-600', 'bg-gray-400')
      html_options[:title] = "You don't have permission to perform this action"
      return button_tag(text, html_options)
    end

    link_to(text, path, html_options)
  end

  def permission_badge(permission_name)
    content_tag :span, permission_name.to_s.titleize,
      class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
  end

  def role_badge(role_name, options = {})
    classes = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium "
    classes += case role_name
              when "Super Admin"
                "bg-purple-100 text-purple-800"
              when "Content Manager"
                "bg-green-100 text-green-800"
              when "Support Agent"
                "bg-blue-100 text-blue-800"
              when "Analytics Manager"
                "bg-yellow-100 text-yellow-800"
              when "Course Instructor"
                "bg-indigo-100 text-indigo-800"
              when "Community Manager"
                "bg-pink-100 text-pink-800"
              else
                "bg-gray-100 text-gray-800"
              end

    content_tag :span, role_name, class: classes
  end

  def section_visible?(resource, action = :view)
    return true if current_user.super_admin?
    can_access?(resource, action)
  end

  def render_if_allowed(resource, action = :view, &block)
    capture(&block) if section_visible?(resource, action)
  end

  def menu_item(text, path, options = {})
    resource = options.delete(:resource)
    action = options.delete(:action) || :view
    icon = options.delete(:icon)
    
    return unless nav_item_visible?(resource, action)

    active = current_page?(path)
    item_class = "group flex items-center px-2 py-2 text-sm font-medium rounded-md " +
                 (active ? "bg-gray-100 text-gray-900" : "text-gray-600 hover:bg-gray-50 hover:text-gray-900")

    link_to path, class: item_class do
      concat icon_tag(icon) if icon
      concat text
      if options[:badge]
        concat content_tag(:span, options[:badge],
          class: "ml-auto inline-block py-0.5 px-3 text-xs font-medium rounded-full " +
                 "#{active ? 'bg-gray-200' : 'bg-gray-100'}")
      end
    end
  end

  def icon_tag(name)
    content_tag :span, class: "mr-3 flex-shrink-0 h-6 w-6" do
      render partial: "admin/shared/icons/#{name}"
    end
  end

  def action_menu(title, options = {}, &block)
    return unless block_given?

    content_tag :div, class: "relative inline-block text-left" do
      concat(
        button_tag(
          type: "button",
          class: "inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500",
          data: { action: "click->dropdown#toggle" }
        ) do
          concat title
          concat content_tag(:svg, class: "ml-2 -mr-1 h-5 w-5", xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 20 20", fill: "currentColor") do
            content_tag :path, nil, fill_rule: "evenodd", d: "M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z", clip_rule: "evenodd"
          end
        end
      )

      concat(
        content_tag(:div,
          class: "origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 focus:outline-none",
          role: "menu",
          aria: { orientation: "vertical", labelledby: "menu-button" },
          tabindex: "-1",
          data: { dropdown_target: "menu" }
        ) do
          capture(&block)
        end
      )
    end
  end

  def stats_card(title, value, options = {})
    content_tag :div, class: "px-4 py-5 bg-white shadow rounded-lg overflow-hidden sm:p-6" do
      concat(content_tag(:dt, title, class: "text-sm font-medium text-gray-500 truncate"))
      concat(content_tag(:dd, class: "mt-1 text-3xl font-semibold text-gray-900") do
        if options[:currency]
          concat(content_tag(:span, options[:currency], class: "text-xl mr-1"))
        end
        concat(value.to_s)
        if options[:suffix]
          concat(content_tag(:span, options[:suffix], class: "text-xl ml-1"))
        end
      end)
    end
  end
end
