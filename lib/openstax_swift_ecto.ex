defmodule OpenStax.Swift.Ecto do
  use Application


  def version do
    "0.1.0"
  end


  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = []
    opts = [strategy: :one_for_one, name: OpenStax.Swift.Ecto]
    Supervisor.start_link(children, opts)
  end
end
