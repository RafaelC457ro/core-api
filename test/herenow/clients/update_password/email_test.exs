defmodule Herenow.Clients.UpdatePassword.EmailTest do
  use Herenow.DataCase
  use Bamboo.Test

  alias Herenow.{Clients, Fixtures}
  alias Herenow.Clients.Storage.Mutator
  alias Herenow.Clients.UpdatePassword.SuccessEmail

  @client_attrs Fixtures.client_attrs()

  @valid_attrs %{
    "client_id" => 1,
    "current_password" => @client_attrs["password"],
    "password" => "new password"
  }

  def client_fixture() do
    {:ok, client} = Mutator.create(@client_attrs)

    client
  end

  describe "update_password/1" do
    test "after password change, the user gets an email" do
      client = client_fixture()

      attrs =
        @valid_attrs
        |> Map.put("client_id", client.id)

      {:ok, client} = Clients.update_password(attrs)

      assert_delivered_email(SuccessEmail.create(client))
    end
  end
end
