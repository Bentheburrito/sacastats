defmodule SacaStatsWeb.InputHelpers do
  use Phoenix.HTML

  alias Phoenix.HTML.Form

  def array_input(form, field, opts \\ [], data \\ []) do
    type = Form.input_type(form, field)
    name = Form.input_name(form, field) <> "[]"
    opts = Keyword.put_new(opts, :name, name)

    content_tag :li do
      [
        apply(Form, type, [form, field, opts]),
        link("Remove", to: "#", data: data, title: "Remove", class: "remove-array-item")
      ]
    end
  end
end
