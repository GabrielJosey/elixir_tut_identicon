defmodule Identicon do
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    # giving the name of the image whatever the image is
    |> save_image(input)
  end

  def save_image(image, input) do
    File.write("#{input}.png", image)
  end

  # Note that this does not have the "= image" on the end
  # That is because we do not need it since this is the last function.
  # The previous functions needed the additional data carried by the
  # image struct. All we need is the color and pixel map
  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      Enum.map(grid, fn {_code, index} ->
        horizontal = rem(index, 5) * 50
        vertical = div(index, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        {top_left, bottom_right}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid =
      Enum.filter(grid, fn {code, _index} ->
        rem(code, 2) == 0
      end)

    %Identicon.Image{image | grid: grid}
  end

  def build_grid(%Identicon.Image{hex: hex} = image) do
    # adding all of the below code to the grid so we
    # can add it to our image grid
    grid =
      hex
      # break list of numbers into chunks (lists) of three
      # In other words create lists of lists by 3s
      # |> Enum.chunk(3)
      |> Enum.chunk_every(3, 3, :discard)
      # itterate through each list in the list
      # and call mirror row
      |> Enum.map(&mirror_row/1)
      # Take all that and turn it all back into one big list
      |> List.flatten()
      # iterate through list and return each number with
      # an index in a two element tuple. The first element
      # being the nuber and the second being the index
      |> Enum.with_index()

    %Identicon.Image{image | grid: grid}
  end

  # take a given list, take the first two items
  # and append them to the end of the list
  # in reverse order ex. [1, 2, 3]
  # would be come [1, 2, 3, 2, 1]
  def mirror_row(row) do
    [first, second | _tail] = row
    row ++ [second, first]
  end

  # psses in only the first three numbers of the hash
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    # add color to image struct
    %Identicon.Image{image | color: {r, g, b}}
  end

  def hash_input(input) do
    # starting with the ":" means we are actually calling from Erlang
    # hash() converts the input into md5 format.
    hex =
      :crypto.hash(:md5, input)
      # converts the above into a list
      |> :binary.bin_to_list()

    # adding the hex to the image struct
    # This is important primarily so it can be caried throughout the process
    # for the purpose of manipulating to make the other pieces of data
    %Identicon.Image{hex: hex}
  end
end
