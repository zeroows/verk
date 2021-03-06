defmodule Verk.Queue.Supervisor do
  @moduledoc """
  Supervisor definition for a queue. It consists of:
  * A `Verk.QueueManager`
  * A poolboy pool of workers
  * A `Verk.WorkersManager`
  """
  use Supervisor
  alias Verk.{WorkersManager, QueueManager}

  @doc false
  def start_link(name, size) do
    Supervisor.start_link(__MODULE__, [name, size], name: name(name))
  end

  @doc false
  def init([name, size]) do
    pool_name = String.to_atom("#{name}.pool")
    workers_manager = WorkersManager.name(name)
    queue_manager = QueueManager.name(name)
    children = [worker(QueueManager, [queue_manager, name], id: queue_manager),
                poolboy_spec(pool_name, size),
                worker(WorkersManager, [workers_manager, name, queue_manager, pool_name, size], id: workers_manager)]

    supervise(children, strategy: :one_for_one)
  end

  defp poolboy_spec(pool_name, pool_size) do
    args = [[name: {:local, pool_name}, worker_module: Verk.Worker, size: pool_size, max_overflow: 0], []]
    worker(:poolboy, args, restart: :permanent, shutdown: 5000, id: pool_name)
  end

  @doc false
  def name(queue) do
    String.to_atom("#{queue}.supervisor")
  end

  @doc false
  def child_spec(queue, size) when is_atom(queue) do
    supervisor(Verk.Queue.Supervisor, [queue, size], id: name(queue))
  end
end
