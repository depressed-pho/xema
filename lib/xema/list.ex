defmodule Xema.List do
  @moduledoc """
  TODO
  """

  @behaviour Xema

  defstruct items: nil,
            min_items: nil,
            max_items: nil,
            additional_items: false,
            unique_items: nil,
            as: :list

  alias Xema.List

  @spec keywords(list) :: %List{}
  def keywords(keywords), do: struct(%List{}, keywords)

  @spec is_valid?(%List{}, any) :: boolean
  def is_valid?(keywords, list), do: validate(keywords, list) == :ok

  @spec validate(%List{}, any) :: :ok | {:error, atom, any}
  def validate(keywords, list) do
    with :ok <- type(keywords, list),
         :ok <- min_items(keywords, list),
         :ok <- max_items(keywords, list),
         :ok <- items(keywords, list),
         :ok <- unique(keywords, list),
      do: :ok
  end

  defp type(_keywords, list) when is_list(list), do: :ok
  defp type(keywords, _list),
    do: {:error, :wrong_type, %{type: keywords.as}}

  defp min_items(%List{min_items: nil}, _list), do: :ok
  defp min_items(%List{min_items: min_items}, list)
    when length(list) < min_items,
    do: {:error, %{min_items: min_items}}
  defp min_items(_keywords, _list), do: :ok

  defp max_items(%List{max_items: nil}, _list), do: :ok
  defp max_items(%List{max_items: max_items}, list)
    when length(list) > max_items,
    do: {:error, %{max_items: max_items}}
  defp max_items(_keywords, _list), do: :ok

  defp unique(%List{unique_items: nil}, _list), do: :ok
  defp unique(%List{unique_items: true}, list) do
    if is_unique?(list),
      do: :ok,
      else: {:error, :not_unique, %{}}
  end

  defp is_unique?(list, set \\ %{})
  defp is_unique?([], _), do: true
  defp is_unique?([h|t], set) do
    case set do
      %{^h => true} -> false
      _ -> is_unique?(t, Map.put(set, h, true))
    end
  end

  defp items(%List{items: nil}, _list), do: :ok
  defp items(%List{items: items, additional_items: additional_items}, list)
    when is_list(items),
    do: items_tuple(items, additional_items, list, 0)
  defp items(%List{items: items}, list) do
    items_list(items, list, 0)
  end

  defp items_list(_schema, [], _at), do: :ok
  defp items_list(schema, [item|list], at) do
    case Xema.validate(schema, item) do
      :ok -> items_list(schema, list, at + 1)
      error -> {:error, :invalid_item, %{at: at, error: error}}
    end
  end

  defp items_tuple([], _additonal_items, [], _at), do: :ok
  defp items_tuple(_schemas, _additonal_items, [], at),
    do: {:error, :missing_value, %{at: at}}
  defp items_tuple([], true, _additonal_items, at),
    do: {:error, :extra_value, %{at: at}}
  defp items_tuple([], false, _additonal_items, _at), do: :ok
  defp items_tuple([schema|schemas], additional_items, [item|list], at) do
    case Xema.validate(schema, item) do
      :ok -> items_tuple(schemas, additional_items, list, at + 1)
      error -> {:error, :invalid_item, %{at: at, error: error}}
    end
  end
end