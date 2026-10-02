defmodule CraftingSoftwareJobProcessingChallengeWeb.JobControllerTest do
  use CraftingSoftwareJobProcessingChallengeWeb.ConnCase

  describe "POST /api/jobs/sort-tasks " do
    test "returns tasks in dependency order", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "touch /tmp/file1"
          },
          %{
            "name" => "task-2",
            "command" => "cat /tmp/file1",
            "requires" => ["task-3"]
          },
          %{
            "name" => "task-3",
            "command" => "echo 'Hello World!' > /tmp/file1",
            "requires" => ["task-1"]
          },
          %{
            "name" => "task-4",
            "command" => "rm /tmp/file1",
            "requires" => ["task-2", "task-3"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 200)

      assert Enum.map(response["tasks"], & &1["name"]) == [
               "task-1",
               "task-3",
               "task-2",
               "task-4"
             ]
    end

    test "returns 400 for circular dependency", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => ["task-3"]
          },
          %{
            "name" => "task-2",
            "command" => "echo 2",
            "requires" => ["task-1"]
          },
          %{
            "name" => "task-3",
            "command" => "echo 3",
            "requires" => ["task-2"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid fields: Circular 'requires' dependency detected."
    end

    test "returns 400 for duplicate task names", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1"
          },
          %{
            "name" => "task-1",
            "command" => "echo 2"
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid task name. task-1 has duplicate name."
    end

    test "returns 400 when task requires itself", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => ["task-1"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid fields. task-1 must not 'require' itself"
    end

    test "returns 400 when required task does not exist", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => ["task-99"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "required tasks do not exist"
    end

    test "waits for all dependencies", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1"
          },
          %{
            "name" => "task-2",
            "command" => "echo 2",
            "requires" => ["task-1"]
          },
          %{
            "name" => "task-3",
            "command" => "echo 3",
            "requires" => ["task-1"]
          },
          %{
            "name" => "task-4",
            "command" => "echo 4",
            "requires" => ["task-2", "task-5"]
          },
          %{
            "name" => "task-5",
            "command" => "echo 5",
            "requires" => ["task-1", "task-3"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 200)

      assert Enum.map(response["tasks"], & &1["name"]) == [
               "task-1",
               "task-2",
               "task-3",
               "task-5",
               "task-4"
             ]
    end

    test "returns 400 when requires is not a list", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => "task-2"
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid fields. 'requires' must be a list."
    end

    test "returns 400 when requires contains non-string", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => [123]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid fields. 'requires' must contain strings"
    end

    test "accepts empty requires", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => []
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks", params)

      response = json_response(conn, 200)

      assert Enum.map(response["tasks"], & &1["name"]) == ["task-1"]
    end
  end

  describe "POST /api/jobs/sort-tasks/bash " do
    test "returns in bash script", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "touch /tmp/file1"
          },
          %{
            "name" => "task-2",
            "command" => "cat /tmp/file1",
            "requires" => ["task-3"]
          },
          %{
            "name" => "task-3",
            "command" => "echo 'Hello World!' > /tmp/file1",
            "requires" => ["task-1"]
          },
          %{
            "name" => "task-4",
            "command" => "rm /tmp/file1",
            "requires" => ["task-2", "task-3"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      assert response(conn, 200) ==
               """
               #!/usr/bin/env bash
               touch /tmp/file1
               echo 'Hello World!' > /tmp/file1
               cat /tmp/file1
               rm /tmp/file1
               """
    end

    test "returns 400 for circular dependency", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => ["task-3"]
          },
          %{
            "name" => "task-2",
            "command" => "echo 2",
            "requires" => ["task-1"]
          },
          %{
            "name" => "task-3",
            "command" => "echo 3",
            "requires" => ["task-2"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid fields: Circular 'requires' dependency detected."
    end

    test "POST /api/jobs/sort-tasks returns 400 for duplicate task names", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1"
          },
          %{
            "name" => "task-1",
            "command" => "echo 2"
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid task name. task-1 has duplicate name."
    end

    test "POST /api/jobs/sort-tasks returns 400 when task requires itself", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => ["task-1"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid fields. task-1 must not 'require' itself"
    end

    test "POST /api/jobs/sort-tasks returns 400 when required task does not exist", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => ["task-99"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "required tasks do not exist"
    end

    test "POST /api/jobs/sort-tasks waits for all dependencies", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1"
          },
          %{
            "name" => "task-2",
            "command" => "echo 2",
            "requires" => ["task-1"]
          },
          %{
            "name" => "task-3",
            "command" => "echo 3",
            "requires" => ["task-1"]
          },
          %{
            "name" => "task-4",
            "command" => "echo 4",
            "requires" => ["task-2", "task-5"]
          },
          %{
            "name" => "task-5",
            "command" => "echo 5",
            "requires" => ["task-1", "task-3"]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      assert response(conn, 200) ==
               """
               #!/usr/bin/env bash
               echo 1
               echo 2
               echo 3
               echo 5
               echo 4
               """
    end

    test "POST /api/jobs/sort-tasks returns 400 when requires is not a list", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => "task-2"
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid fields. 'requires' must be a list."
    end

    test "POST /api/jobs/sort-tasks returns 400 when requires contains non-string", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => [123]
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      response = json_response(conn, 400)

      assert response["error"] =~ "Invalid fields. 'requires' must contain strings"
    end

    test "POST /api/jobs/sort-tasks accepts empty requires", %{conn: conn} do
      params = %{
        "tasks" => [
          %{
            "name" => "task-1",
            "command" => "echo 1",
            "requires" => []
          }
        ]
      }

      conn = post(conn, ~p"/api/jobs/sort-tasks/bash", params)

      assert response(conn, 200) ==
               """
               #!/usr/bin/env bash
               echo 1
               """
    end
  end
end
