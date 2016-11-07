require IEx;

defmodule Mighty.EdgarController do
  use Mighty.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def connect() do
    {:ok, pid} = :inets.start(:ftpc, host: 'ftp.sec.gov')
    :ftp.user(pid, 'anonymous', '')
    pid
  end

  def disconnect(pid) do
    :ftp.close(pid)
    :inets.stop(:ftpc, pid)
  end

  def fetch_year(year) do
    pid = connect
    fetch_year(pid, year)
    disconnect(pid)
  end
  def fetch_year(pid, year) do
    :ok = :ftp.cd(pid, '/edgar/full-index/#{year}')
    {:ok, quarters} = :ftp.nlist(pid)
    quarter_list = String.split to_string(quarters)
    Enum.map(quarter_list, &fetch_quarter(pid, year, &1))
  end

  def fetch_quarter(year, quarter) do
    pid = connect
    fetch_quarter(pid, year, quarter)
    disconnect(pid)
  end
  def fetch_quarter(pid, year, quarter) do
    IO.puts("fetch_quarter #{year}, #{quarter}")
    :ok = :ftp.cd(pid, '/edgar/full-index/#{year}/#{quarter}')
    :ok = :ftp.recv(pid, 'master.idx', '#{year}-#{quarter}-master.idx')
  end

  def fetch_file(fullpath) do
    pid = connect
    fetch_file(pid, fullpath)
    disconnect(pid)
  end
  def fetch_file(pid, fullpath) do
    File.mkdir_p!(Path.dirname(fullpath))
    path = to_char_list fullpath
    :ok = :ftp.cd(pid, '/')
    :ok = :ftp.recv(pid, path, path)
  end

  def index_entries(company) do
    index_entries(company, "*-master.idx")
  end
  def index_entries(company, year) when is_number(year) do
    index_entries(company, "#{year}-*-master.idx")
  end
  def index_entries(company, files) do
    {lines, 0} = System.cmd("find", [".", "-name", files, "-exec", "grep", "-i", company, "{}", "\;"])
    String.split(lines, "\r\n")
  end

  def filter_by_type(entries, type) do
    Enum.filter(entries, &String.match?(&1, ~r/#{type}/))
  end
  def ftp_file_path(entry) do
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
