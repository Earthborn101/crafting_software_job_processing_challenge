defmodule CraftingSoftwareJobProcessingChallengeWeb.Router do
  use CraftingSoftwareJobProcessingChallengeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CraftingSoftwareJobProcessingChallengeWeb do
    pipe_through :api

    post "/jobs/sort-tasks", JobsController, :sort_tasks
    post "/jobs/sort-tasks/bash", JobsController, :sort_tasks_bash
  end
end
