defmodule ExSubtilBackendWeb.Docker.HostsController do
  use ExSubtilBackendWeb, :controller

  def list_hosts() do
    config_hosts = Application.get_env(:ex_subtil_backend, :docker_hosts)
    Enum.map config_hosts, fn host ->
      RemoteDockers.DockerHostConfig.new(
        host[:hostname],
        host[:port],
        host[:certfile],
        host[:keyfile]
      )
    end
  end

  def index(conn, _) do
    hosts = list_hosts()
    render(conn, "index.json", %{hosts: hosts})
  end

end