defmodule EversignTest do
  use ExUnit.Case
  doctest Eversign

  test "creates a document" do
    assert Eversign.create_document() == :world
  end

  test "lists all documents" do
    assert Eversign.list_documents() == :world
  end
end
