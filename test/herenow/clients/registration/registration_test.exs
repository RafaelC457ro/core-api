defmodule Herenow.Clients.RegistrationTest do
  use Herenow.DataCase, async: true

  alias Herenow.{Clients, Fixtures}
  alias Herenow.Clients.Storage.{Mutator, Loader}

  @valid_attrs Fixtures.client_attrs()

  def client_fixture(attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Mutator.create()

    client
  end

  describe "register/1" do
    test "missing keys" do
      attrs =
        @valid_attrs
        |> Map.drop(["postal_code", "city", "email"])

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "city",
              "message" => "can't be blank",
              "type" => :required
            },
            %{
              "field" => "email",
              "message" => "can't be blank",
              "type" => :required
            },
            %{
              "field" => "postal_code",
              "message" => "can't be blank",
              "type" => :required
            }
          ]}}

      assert actual == expected
    end

    test "invalid type of keys" do
      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "is_company",
              "message" => "is invalid",
              "type" => :cast
            }
          ]}}

      attrs =
        @valid_attrs
        |> Map.put("is_company", "some string")

      actual = Clients.register(attrs)
      assert actual == expected
    end

    test "invalid captcha" do
      attrs =
        @valid_attrs
        |> Map.put("captcha", "invalid")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => nil,
              "message" => "Invalid captcha",
              "type" => :invalid_captcha
            }
          ]}}

      assert actual == expected
    end

    test "email should be unique" do
      client = client_fixture()

      attrs =
        @valid_attrs
        |> Map.put("email", client.email)

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "email",
              "message" => "has already been taken",
              "type" => :unique
            }
          ]}}

      assert actual == expected
    end

    test "email should have less than 255 characters" do
      email =
        @valid_attrs
        |> Map.get("email")
        |> String.pad_leading(256, "abc")

      attrs =
        @valid_attrs
        |> Map.put("email", email)

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "email",
              "message" => "should be at most 254 character(s)",
              "type" => :length
            }
          ]}}

      assert actual == expected
    end

    test "email should have a @" do
      attrs =
        @valid_attrs
        |> Map.put("email", "invalidemail")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "email",
              "message" => "has invalid format",
              "type" => :format
            }
          ]}}

      assert actual == expected
    end

    test "postal_code should have exact 8 characters, less should return error" do
      attrs =
        @valid_attrs
        |> Map.put("postal_code", "1234")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "postal_code",
              "message" => "should be 8 character(s)",
              "type" => :length
            }
          ]}}

      assert actual == expected
    end

    test "postal_code should have exact 8 characters, more should return error" do
      attrs =
        @valid_attrs
        |> Map.put("postal_code", "123456789")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "postal_code",
              "message" => "should be 8 character(s)",
              "type" => :length
            }
          ]}}

      assert actual == expected
    end

    test "password should have at least 8 characters" do
      attrs =
        @valid_attrs
        |> Map.put("password", "abcdefg")

      actual = Clients.register(attrs)

      expected =
        {:error,
         {:validation,
          [
            %{
              "field" => "password",
              "message" => "should be at least 8 character(s)",
              "type" => :length
            }
          ]}}

      assert actual == expected
    end

    test "should return the client's information" do
      {:ok, client} = Clients.register(@valid_attrs)

      assert client.latitude == @valid_attrs["latitude"]
      assert client.longitude == @valid_attrs["longitude"]
      assert client.postal_code == @valid_attrs["postal_code"]
      assert client.city == @valid_attrs["city"]
      assert client.email == @valid_attrs["email"]
      assert client.is_company == @valid_attrs["is_company"]
      assert client.legal_name == @valid_attrs["legal_name"]
      assert client.name == @valid_attrs["name"]
      assert client.segment == @valid_attrs["segment"]
      assert client.state == @valid_attrs["state"]
      assert client.street_address == @valid_attrs["street_address"]
    end

    test "should persist the client" do
      {:ok, client} = Clients.register(@valid_attrs)
      persisted_client = Loader.get!(client.id)

      assert client.id == persisted_client.id
      assert client.latitude == persisted_client.latitude
      assert client.longitude == persisted_client.longitude
      assert client.postal_code == persisted_client.postal_code
      assert client.city == persisted_client.city
      assert client.email == persisted_client.email
      assert client.is_company == persisted_client.is_company
      assert client.legal_name == persisted_client.legal_name
      assert client.name == persisted_client.name
      assert client.segment == persisted_client.segment
      assert client.state == persisted_client.state
      assert client.street_address == persisted_client.street_address
      assert client.inserted_at == persisted_client.inserted_at
      assert client.updated_at == persisted_client.updated_at
    end
  end
end
