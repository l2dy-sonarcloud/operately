defmodule Operately.Goals.Timeframe do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:type, :start_date, :end_date]}

  def fetch(term, key) when is_atom(key) do
    {:ok, Map.get(term, key)}
  end

  def fetch(term, key) when is_binary(key) do
    {:ok, Map.get(term, String.to_existing_atom(key))}
  end

  embedded_schema do
    field :type, :string
    field :start_date, :date
    field :end_date, :date
  end

  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(timeframe, attrs) when is_struct(attrs, __MODULE__) do
    changeset(timeframe, Map.from_struct(attrs))
  end

  def changeset(timeframe, attrs) do
    timeframe
    |> cast(attrs, [:type, :start_date, :end_date])
    |> validate_required([:type, :start_date, :end_date])
    |> validate_inclusion(:type, ["year", "quarter", "month", "days"])
    |> validate_start_is_before_end()
    |> validate_year_dates()
    |> validate_quarter_dates()
    |> validate_month_dates()
  end

  def current_year do
    date = Date.utc_today()

    %__MODULE__{
      start_date: beginning_of_year(date),
      end_date: end_of_year(date),
      type: "year"
    }
  end

  def last_year do
    date = Date.utc_today() |> Date.add(-365)

    %__MODULE__{
      start_date: beginning_of_year(date),
      end_date: end_of_year(date),
      type: "year"
    }
  end

  def current_quarter do
    today = Date.utc_today()
    year = today.year

    cond do
      today.month in 1..3 -> quarter(year, "01-01", "03-31")
      today.month in 4..6 -> quarter(year, "04-01", "06-30")
      today.month in 7..9 -> quarter(year, "07-01", "09-30")
      today.month in 10..12 -> quarter(year, "10-01", "12-31")
    end
  end

  def next_quarter do
    today = Date.utc_today()
    year = today.year

    cond do
      today.month in 1..3 -> quarter(year, "04-01", "06-30")
      today.month in 4..6 -> quarter(year, "07-01", "09-30")
      today.month in 7..9 -> quarter(year, "10-01", "12-31")
      today.month in 10..12 -> quarter(year + 1, "01-01", "03-31")
    end
  end

  def validate_start_is_before_end(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if Date.compare(start_date, end_date) != :lt do
      add_error(changeset, :end_date, "End date must be after start date")
    else
      changeset
    end
  end

  def validate_year_dates(changeset) do
    type = get_field(changeset, :type)
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if type == "year" do
      cond do
        start_date.month != 1 or start_date.day != 1 ->
          add_error(changeset, :start_date, "Start date must be the first day of the year")

        end_date.month != 12 or end_date.day != 31 ->
          add_error(changeset, :end_date, "End date must be the last day of the year")

        end_date.year - start_date.year != 0 ->
          add_error(changeset, :end_date, "Start and end date must be in the same year")

        true ->
          changeset
      end
    else
      changeset
    end
  end

  def validate_quarter_dates(changeset) do
    type = get_field(changeset, :type)
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if type == "quarter" do
      cond do
        start_date.year != end_date.year ->
          add_error(changeset, :end_date, "Start and end date must be in the same year")

        start_date.month not in [1, 4, 7, 10] or start_date.day != 1 ->
          add_error(changeset, :start_date, "Start date must be the first day of the quarter")

        end_date.month not in [3, 6, 9, 12] or end_date.day != Date.days_in_month(end_date) ->
          add_error(changeset, :end_date, "End date must be the last day of the quarter")

        end_date.month - start_date.month != 2 ->
          add_error(changeset, :end_date, "Start and end date must be in the same quarter")

        true ->
          changeset
      end
    else
      changeset
    end
  end

  def validate_month_dates(changeset) do
    type = get_field(changeset, :type)
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if type == "month" do
      cond do
        start_date.year != end_date.year ->
          add_error(changeset, :end_date, "Start and end date must be in the same year")

        start_date.day != 1 ->
          add_error(changeset, :start_date, "Start date must be the first day of the month")

        end_date.day != Date.days_in_month(end_date) ->
          add_error(changeset, :end_date, "End date must be the last day of the month")

        true ->
          changeset
      end
    else
      changeset
    end
  end

  def convert_old_timeframe(old_timeframe) do
    parts = String.split(old_timeframe, " ")

    if Enum.count(parts) == 1 do
      [year] = parts

      %{
        start_date: Date.from_iso8601!("#{year}-01-01"),
        end_date: Date.from_iso8601!("#{year}-12-31"),
        type: "year"
      }
    else
      [quarter, year] = parts

      [start_date, end_date] =
        case quarter do
          "Q1" -> ["01-01", "03-31"]
          "Q2" -> ["04-01", "06-30"]
          "Q3" -> ["07-01", "09-30"]
          "Q4" -> ["10-01", "12-31"]
        end

      %{
        start_date: Date.from_iso8601!("#{year}-#{start_date}"),
        end_date: Date.from_iso8601!("#{year}-#{end_date}"),
        type: "quarter"
      }
    end
  end

  def parse_json!(json) when is_binary(json) do
    parse_json!(Jason.decode!(json))
  end

  def parse_json!(map) do
    %{"start_date" => start_date, "end_date" => end_date, "type" => type} = map

    %__MODULE__{
      start_date: Date.from_iso8601!(start_date),
      end_date: Date.from_iso8601!(end_date),
      type: type
    }
  end

  defp beginning_of_year(date) do
    {year, _, _} = Date.to_erl(date)
    Date.from_erl!({year, 1, 1})
  end

  defp end_of_year(date) do
    {year, _, _} = Date.to_erl(date)
    Date.from_erl!({year, 12, 31})
  end

  defp quarter(year, start_date, end_date) do
    %{
      start_date: Date.from_iso8601!("#{year}-#{start_date}"),
      end_date: Date.from_iso8601!("#{year}-#{end_date}"),
      type: "quarter"
    }
  end
end
