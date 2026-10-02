defmodule CraftingSoftwareJobProcessingChallengeWeb.JobsController do
  use CraftingSoftwareJobProcessingChallengeWeb, :controller

  alias CraftingSoftwareJobProcessingChallenge.Jobs

  @spec sort_tasks(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def sort_tasks(conn, %{"tasks" => tasks}) do
    case Jobs.sort_tasks(tasks) do
      {:ok, tasks} ->
        json(conn, %{tasks: tasks})

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  def sort_tasks(conn, _params) do
    invalid_missing_task_list(conn)
  end

  @spec sort_tasks_bash(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def sort_tasks_bash(conn, %{"tasks" => tasks}) do
    case Jobs.sort_tasks(tasks, format: :bash) do
      {:ok, bash_message} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, bash_message)

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  def sort_tasks_bash(conn, _params) do
    invalid_missing_task_list(conn)
  end

  defp invalid_missing_task_list(conn) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid request. Missing tasks list."})
  end
end
