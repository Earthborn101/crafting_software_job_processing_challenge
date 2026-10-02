defmodule CraftingSoftwareJobProcessingChallenge.Jobs do
  @required_fields ["name", "command"]
  @optional_field "requires"

  @allowed_fields @required_fields ++ [@optional_field]

  @spec sort_tasks(any()) :: {:error, any()} | {:ok, <<_::64, _::_*8>> | [map()]}
  def sort_tasks(tasks, opts \\ [format: :json]) do
    with :ok <- validate_tasks_fields(tasks),
         {:ok, tasks} <- sort_task_commands(tasks, [], []) do
      format = Keyword.get(opts, :format)

      if format == :json do
        {:ok, tasks}
      else
        {:ok, to_bash(tasks)}
      end
    else
      {:error, message} ->
        {:error, message}
    end
  end

  defp validate_tasks_fields(tasks) do
    task_set_map = %{
      task_names: MapSet.new(),
      dependencies: MapSet.new(),
      tasks_with_dependencies: MapSet.new()
    }

    validated_task_name_list =
      Enum.reduce_while(tasks, task_set_map, fn task, result ->
        with :ok <- validate_if_allowed_fields(task),
             :ok <- validate_required_task_fields(task),
             :ok <- validate_unique_task_name(task, result.task_names),
             {:ok, requires, tasks_with_dependencies} <-
               validate_optional_require_field(task, result) do
          {:cont,
           %{
             task_names: MapSet.put(result.task_names, task["name"]),
             dependencies:
               MapSet.union(
                 result.dependencies,
                 MapSet.new(requires)
               ),
             tasks_with_dependencies:
               MapSet.put(
                 result.tasks_with_dependencies,
                 tasks_with_dependencies
               )
           }}
        else
          {:error, message} ->
            {:halt, {:error, message}}
        end
      end)

    case validated_task_name_list do
      %{task_names: task_names, dependencies: dependencies} ->
        validate_dependencies_exist(task_names, dependencies)

      {:error, message} ->
        {:error, message}
    end
  end

  defp validate_if_allowed_fields(task) do
    case Map.take(task, @allowed_fields) == task do
      true ->
        :ok

      false ->
        {:error, "Invalid fields. Allowed fields are only 'name', 'command', and 'requires'."}
    end
  end

  defp validate_required_task_fields(task) do
    Enum.reduce_while(@required_fields, :ok, fn field, _acc ->
      case Map.get(task, field) do
        value when is_binary(value) ->
          if String.trim(value) == "" do
            {:halt, {:error, "Invalid fields. Required fields must not be empty."}}
          else
            {:cont, :ok}
          end

        nil ->
          {:halt, {:error, "Invalid fields. 'name' and 'command' are required."}}

        _ ->
          {:halt, {:error, "Invalid fields. 'name' and 'command' must be a string."}}
      end
    end)
  end

  defp validate_unique_task_name(_task, []) do
    :ok
  end

  defp validate_unique_task_name(%{"name" => name}, task_names) do
    if name in task_names do
      {:error, "Invalid task name. #{name} has duplicate name."}
    else
      :ok
    end
  end

  defp validate_optional_require_field(%{"name" => name, "requires" => requires} = tasks, %{
         tasks_with_dependencies: tasks_with_dependencies
       })
       when is_list(requires) do
    cond do
      not Enum.all?(requires, &is_binary/1) ->
        {:error, "Invalid fields. 'requires' must contain strings"}

      name in requires ->
        {:error, "Invalid fields. #{name} must not 'require' itself"}

      true ->
        case Enum.find(tasks_with_dependencies, fn task ->
               task["name"] in requires && name in Map.get(task, "requires", [])
             end) do
          nil ->
            {:ok, requires, tasks}

          invalid_task ->
            {:error,
             "Invalid fields. #{name} cannot also be 'requires' for #{invalid_task["name"]}"}
        end
    end
  end

  defp validate_optional_require_field(%{"requires" => requires}, _result)
       when not is_list(requires) do
    {:error, "Invalid fields. 'requires' must be a list."}
  end

  defp validate_optional_require_field(_task, _result) do
    {:ok, [], %{}}
  end

  defp validate_dependencies_exist(task_names, dependencies) do
    if MapSet.subset?(dependencies, task_names) do
      :ok
    else
      {:error, "Invalid fields. One or more required tasks do not exist."}
    end
  end

  defp sort_task_commands(tasks, completed_tasks_names, completed_tasks) do
    case Enum.find(tasks, fn task ->
           requires = Map.get(task, "requires", [])

           Enum.all?(requires, &(&1 in completed_tasks_names))
         end) do
      nil ->
        if tasks == [] do
          {:ok, completed_tasks}
        else
          {:error, "Invalid fields: Circular 'requires' dependency detected."}
        end

      task ->
        remaining_tasks = List.delete(tasks, task)

        sort_task_commands(
          remaining_tasks,
          completed_tasks_names ++ [task["name"]],
          completed_tasks ++ [Map.delete(task, "requires")]
        )
    end
  end

  defp to_bash(tasks) do
    commands =
      tasks
      |> Enum.map(& &1["command"])
      |> Enum.join("\n")

    "#!/usr/bin/env bash\n" <> commands <> "\n"
  end
end
