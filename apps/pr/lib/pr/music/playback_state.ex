defmodule PR.Music.PlaybackState do
  defstruct [
    :position,
    :state
  ]

  alias PR.Music.PlaybackState

  @spec new(map()) :: PlaybackState.t()
  def new(%{
    position_millis: position,
    playback_state: playback_state
  }) do
    %__MODULE__{
      position: position,
      state: state(playback_state)
    }
  end

  def label(:paued), do: "Paused"
  def label(:buffering), do: "Buffering"
  def label(:playing), do: "Playing"
  def label(_), do: nil

  defp state("PLAYBACK_STATE_PAUSED"), do: :paused
  defp state("PLAYBACK_STATE_BUFFERING"), do: :buffering
  defp state("PLAYBACK_STATE_PLAYING"), do: :playing
  defp state(_), do: nil

end
