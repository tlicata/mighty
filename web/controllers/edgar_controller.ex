require IEx;

defmodule Mighty.EdgarController do
  use Mighty.Web, :controller

  @edgar_url "https://www.sec.gov/Archives"

  def index(conn, _params) do
    render conn, "index.html"
  end

  def fetch_year(year) do
    %HTTPoison.Response{status_code: 200, body: body} =
      HTTPoison.get! "#{@edgar_url}/edgar/full-index/#{year}/index.json"

    %{"directory" => %{"item" => items}} = Poison.decode!(body)
    quarters = for %{"name" => qtr} <- items, do: qtr
    Enum.map(quarters, fn(qtr) ->
      spawn(&fetch_quarter(year, qtr))
    end)
  end

  def fetch_quarter(year, quarter) do
    IO.puts("fetch_quarter #{year}, #{quarter}...")

    %HTTPoison.Response{status_code: 200, body: body} =
      HTTPoison.get! "#{@edgar_url}/edgar/full-index/#{year}/#{quarter}/master.idx"

    File.write("#{year}-#{quarter}-master.idx", body)
    IO.puts("fetch_quarter #{year}, #{quarter} finished.")
  end

  def fetch_file(fullpath) do
    %HTTPoison.Response{status_code: 200, body: body} =
      HTTPoison.get! "#{@edgar_url}/#{fullpath}"

    File.mkdir_p!(Path.dirname(fullpath))

    File.write(fullpath, body)
  end

  def index_entries(company) do
    index_entries(company, "*-master.idx")
  end
  def index_entries(company, year) when is_number(year) do
    index_entries(company, "#{year}-*-master.idx")
  end
  def index_entries(company, files) do
    {lines, 0} = System.cmd("find", [".", "-name", files, "-exec", "grep", "-i", company, "{}", "\;"])
    String.split(lines, "\n")
  end

  def filter_by_type(entries, type) do
    Enum.filter(entries, &String.match?(&1, ~r/#{type}/))
  end
  def file_path(entry) do
    List.last String.split(entry, "|")
  end

  def find_attribute(line, attribute) do
    [_, value] = Regex.run(~r/#{attribute}="(\w+)"/, line)
    value
  end
  def find_node_value(line) do
    [_, value] = Regex.run(~r/>(.+)</, line)
    value
  end
  def find_in_file(filename, tag) do
    {lines, 0} = System.cmd("grep", [tag, filename])
    lines |> String.strip |> String.split("\n")
  end
  def find_earnings_per_share(filename) do
    Enum.map(
      find_in_file(filename, "us-gaap:EarningsPerShareDiluted"),
      fn(line) -> [period: find_attribute(line, "contextRef"), eps: find_node_value(line)] end
    )
  end
end
