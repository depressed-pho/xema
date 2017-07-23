defmodule Xema.Validator.Number do
  @moduledoc """
  TODO
  """

  import Xema.Helper.Error

  def minimum(%{minimum: nil}, _number), do: :ok
  def minimum(
    %{minimum: minimum, exclusive_minimum: exclusive_minimum},
    number
  ), do: minimum(minimum, exclusive_minimum, number)

  def maximum(%{maximum: nil}, _number), do: :ok
  def maximum(
    %{maximum: maximum, exclusive_maximum: exclusive_maximum},
    number
  ), do: maximum(maximum, exclusive_maximum, number)

  def multiple_of(%{multiple_of: nil}, _number), do: :ok
  def multiple_of(%{multiple_of: multiple_of}, number),
    do: multiple_of(multiple_of, number)

  @spec minimum(number, boolean, number) :: {:error, map}
  def minimum(minimum, _exclusive, number)
    when number > minimum,
    do: :ok
  def minimum(minimum, true, number)
    when number == minimum,
    do: error(:too_small, minimum: minimum, exclusive_minimum: true)
  def minimum(minimum, _exclusive, number)
    when number == minimum,
    do: :ok
  def minimum(minimum, _exclusive, _number),
    do: error(:too_small, minimum: minimum)

  @spec maximum(number, boolean, number) :: {:error, map}
  def maximum(maximum, _exclusive, number)
    when number < maximum,
    do: :ok
  def maximum(maximum, true, number)
    when number == maximum,
    do: error(:too_big, maximum: maximum, exclusive_maximum: true)
  def maximum(maximum, _exclusive, number)
    when number == maximum,
    do: :ok
  def maximum(maximum, _exclusive, _number),
    do: error(:too_big, maximum: maximum)

  @spec multiple_of(number, number) :: :ok | {:error, map}
  def multiple_of(multiple_of, number) do
    x = number / multiple_of
    if x - Float.floor(x) == 0,
      do: :ok,
      else: error(:not_multiple, multiple_of: multiple_of)
  end
end
