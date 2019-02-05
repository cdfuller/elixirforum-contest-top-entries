defmodule ContestParser.CLI do

  def main(_args \\ []) do
    HTTPoison.start

    Enum.each(sources(), fn(page) ->
      query_page(page)
    end)
  end

  def query_page(page_details) do
    response = page_details.url
      |> HTTPoison.get!()

    html = response.body

    [{"div", [{"class", "thismonthsnumber"}], [number_string]}] = html |> Floki.find(".thismonthsnumber")

    target_number = String.to_integer(number_string)

    [ _table_header | entries] = html
      |> Floki.find(".thismonthsentriestable tr")

    users_and_numbers = Enum.map(entries, fn(x) -> parse_entry(x) end)

    IO.puts(page_details.name)

    sort_entries(users_and_numbers, target_number)
    |> print_results(target_number)

    IO.puts("\n\n\n")
  end

  defp parse_entry(entry) do
    # IO.inspect(entry, label: "Entry")
    { "tr", [], [number_row, user_row] } = entry
    { "td", [], [number_str] } = number_row
    { "td", [], [user_str] } = user_row

    number = String.to_integer(number_str)
    [ _, user ] = Regex.run(~r/\s([\w-.]+)'s/, user_str)
    {user, number}
  end

  defp sort_entries(entries, target) do
    Enum.sort_by(entries, fn(entry) ->
      { _, n } = entry
      abs(target - n)
    end)
  end

  defp print_results(entries, target) do
    IO.puts("Target #{target}")
    IO.puts("")
    IO.puts("Diff\t Number\t User")
    IO.puts("----\t ------\t ----")
    Enum.each(entries, fn(entry) ->
      { user, number } = entry
      diff = abs(number - target)
      # IO.puts("#{inspect number}\t diff: #{inspect diff} \t#{user}")
      IO.puts("#{inspect diff}\t #{inspect number}\t #{user}")
    end)
    IO.puts("")
    IO.puts("#{inspect length entries} entries")
  end

  defp sources() do
    [ %{ name: "PragProg", url: "https://pragprog.elixirforum.com/january" },
      %{ name: "Manning", url: "https://manning.elixirforum.com/january" },
      %{ name: "ElixirCasts", url: "https://elixircasts.elixirforum.com/january" }
    ]
  end
end
