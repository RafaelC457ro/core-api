defmodule HerenowWeb.Controllers.Client.RecoverPasswordTest do
  use HerenowWeb.ConnCase, async: true

  alias Herenow.Fixtures
  alias Herenow.Clients.Storage.{Mutator, Loader}
  alias Herenow.Core.Token
  alias Herenow.Clients.PasswordHash

  @expiration_time Application.get_env(
                     :herenow,
                     :password_recovery_expiration_time
                   )
  @secret Application.get_env(:herenow, :password_recovery_secret)
  @client_attrs Fixtures.client_attrs()

  @valid_attrs %{
    "captcha" => "valid",
    "password" => "new password",
    "token" => Token.generate(%{"client_id" => 1}, @secret, @expiration_time)
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  def client_fixture do
    {:ok, client} = Mutator.create(@client_attrs)

    client
  end

  describe "recover_password/2" do
    test "renders client when data is valid", %{conn: conn} do
      client = client_fixture()
      token = Token.generate(%{"client_id" => client.id}, @secret, @expiration_time)

      attrs =
        @valid_attrs
        |> Map.put("token", token)

      conn =
        conn
        |> post(client_path(conn, :recover_password), attrs)

      response = json_response(conn, 200)

      assert is_integer(response["id"])
      assert response["latitude"] == client.latitude
      assert response["longitude"] == client.longitude
      assert response["is_company"] == client.is_company
      assert response["name"] == client.name
      assert response["legal_name"] == client.legal_name
      assert response["segment"] == client.segment
      assert response["state"] == client.state
      assert response["street_address"] == client.street_address
      assert response["postal_code"] == client.postal_code
      assert response["city"] == client.city
      assert response["email"] == client.email
    end

    test "missing keys", %{conn: conn} do
      attrs =
        @valid_attrs
        |> Map.delete("captcha")

      conn =
        conn
        |> post(client_path(conn, :recover_password), attrs)

      actual = json_response(conn, 422)

      expected = %{
        "code" => 100,
        "message" => "Validation failed!",
        "errors" => [
          %{
            "code" => 104,
            "field" => "captcha",
            "message" => "can't be blank"
          }
        ]
      }

      assert actual == expected
    end

    test "invalid type of keys", %{conn: conn} do
      attrs =
        @valid_attrs
        |> Map.put("captcha", 9)

      conn =
        conn
        |> post(client_path(conn, :recover_password), attrs)

      actual = json_response(conn, 422)

      expected = %{
        "code" => 100,
        "message" => "Validation failed!",
        "errors" => [
          %{"code" => 102, "field" => "captcha", "message" => "is invalid"}
        ]
      }

      assert actual == expected
    end

    test "invalid captcha", %{conn: conn} do
      attrs =
        @valid_attrs
        |> Map.put("captcha", "invalid")

      conn =
        conn
        |> post(client_path(conn, :recover_password), attrs)

      actual = json_response(conn, 422)

      expected = %{
        "code" => 100,
        "message" => "Validation failed!",
        "errors" => [
          %{"code" => 101, "field" => nil, "message" => "Invalid captcha"}
        ]
      }

      assert actual == expected
    end

    test "invalid token signature", %{conn: conn} do
      attrs =
        @valid_attrs
        |> Map.put("token", "invalidtoken")

      conn =
        conn
        |> post(client_path(conn, :recover_password), attrs)

      actual = json_response(conn, 422)

      expected = %{
        "code" => 100,
        "message" => "Validation failed!",
        "errors" => [
          %{
            "code" => 108,
            "field" => nil,
            "message" => "Invalid signature"
          }
        ]
      }

      assert actual == expected
    end

    test "expired token", %{conn: conn} do
      current_time = 1

      token = Token.generate(%{"client_id" => 1}, @secret, @expiration_time, current_time)

      attrs =
        @valid_attrs
        |> Map.put("token", token)

      conn =
        conn
        |> post(client_path(conn, :recover_password), attrs)

      actual = json_response(conn, 422)

      expected = %{
        "code" => 100,
        "message" => "Validation failed!",
        "errors" => [
          %{
            "code" => 109,
            "field" => nil,
            "message" => "Expired token"
          }
        ]
      }

      assert actual == expected
    end

    test "used token", %{conn: conn} do
      client = client_fixture()

      token = Token.generate(%{"client_id" => client.id}, @secret, @expiration_time)

      attrs =
        @valid_attrs
        |> Map.put("token", token)

      conn =
        conn
        |> post(client_path(conn, :recover_password), attrs)
        |> post(client_path(conn, :recover_password), attrs)

      actual = json_response(conn, 422)

      expected = %{
        "code" => 100,
        "message" => "Validation failed!",
        "errors" => [
          %{
            "code" => 111,
            "field" => nil,
            "message" => "Already used token"
          }
        ]
      }

      assert actual == expected
    end

    test "weak password", %{conn: conn} do
      attrs =
        @valid_attrs
        |> Map.put("password", "weak")

      conn =
        conn
        |> post(client_path(conn, :recover_password), attrs)

      actual = json_response(conn, 422)

      expected = %{
        "code" => 100,
        "message" => "Validation failed!",
        "errors" => [
          %{
            "code" => 103,
            "field" => "password",
            "message" => "should be at least 8 character(s)"
          }
        ]
      }

      assert actual == expected
    end

    test "change the password", %{conn: conn} do
      client = client_fixture()

      token = Token.generate(%{"client_id" => client.id}, @secret, @expiration_time)

      attrs =
        @valid_attrs
        |> Map.put("token", token)

      post(conn, client_path(conn, :recover_password), attrs)

      persisted_client = Loader.get!(client.id)
      assert {:ok} == PasswordHash.valid?(@valid_attrs["password"], persisted_client.password)

      assert {:error, :invalid_password} ==
               PasswordHash.valid?(@client_attrs["password"], persisted_client.password)
    end

    test "should verify unverified accounts", %{conn: conn} do
      client = client_fixture()

      token = Token.generate(%{"client_id" => client.id}, @secret, @expiration_time)

      attrs =
        @valid_attrs
        |> Map.put("token", token)

      post(conn, client_path(conn, :recover_password), attrs)

      persisted_client = Loader.get!(client.id)
      assert {:ok} == PasswordHash.valid?(@valid_attrs["password"], persisted_client.password)

      assert {:ok, verified_client} = Loader.is_verified?(client.id)
      assert verified_client.client_id == client.id
    end
  end
end
