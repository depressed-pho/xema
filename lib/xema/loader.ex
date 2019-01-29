defmodule Xema.Loader do
  @moduledoc """
  The behaviour for loaders.
  """

  @doc """
  This function expected an URI, to fetch the required data to create a schema.
  """
  @callback fetch(uri :: URI.t()) :: {:ok, any} | {:error, any}
end
