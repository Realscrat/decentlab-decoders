
# https://www.decentlab.com/support

defmodule Parser do
  use Platform.Parsing.Behaviour
  
  ## Test payloads
  # 0203d400033bf67fff3bf60c60
  # 0203d400020c60
  
  def fields do
    [
      %{field: "Counter reading", display: "Counter reading", unit: ""},
      %{field: "Measurement interval", display: "Measurement interval", unit: ""},
      %{field: "Frequency", display: "Frequency", unit: "Hz"},
      %{field: "Weight", display: "Weight", unit: "g"},
      %{field: "Elongation", display: "Elongation", unit: "µm"},
      %{field: "Strain", display: "Strain", unit: "µm⋅m⁻¹"},
      %{field: "Battery voltage", display: "Battery voltage", unit: "V"}
    ]
  end

  def parse(<<2, device_id::size(16), flags::binary-size(2), words::binary>>, _meta) do
    {_remaining, result} =
      {words, %{"Device ID" => device_id, "Protocol version" => 2}}
      |> sensor0(flags)
      |> sensor1(flags)

    result
  end
  
  defp sensor0({<<x0::size(16), x1::size(16), x2::size(16), remaining::binary>>, result},
               <<_::size(15), 1::size(1), _::size(0)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Counter reading" => x0,
                 "Measurement interval" => x1 / 32768,
                 "Frequency" => x0 / x1 * 32768,
                 "Weight" => (:math.pow(x0 / x1 * 32768, 2) - :math.pow((15383.72), 2)) * (46.4859) / 1000000,
                 "Elongation" => (:math.pow(x0 / x1 * 32768, 2) - :math.pow((15383.72), 2)) * (46.4859) / 1000000 * (-1.5) / 1000 * 9.8067,
                 "Strain" => (:math.pow(x0 / x1 * 32768, 2) - :math.pow((15383.72), 2)) * (46.4859) / 1000000 * (-1.5) / 1000 * 9.8067 / 0.066
               })}
  end
  defp sensor0(result, _flags), do: result
  
  defp sensor1({<<x0::size(16), remaining::binary>>, result},
               <<_::size(14), 1::size(1), _::size(1)>>) do
    {remaining,
     Map.merge(result,
               %{
                 "Battery voltage" => x0 / 1000
               })}
  end
  defp sensor1(result, _flags), do: result
  
end