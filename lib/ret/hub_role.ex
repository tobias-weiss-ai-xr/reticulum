defmodule Ret.HubRole do
  @moduledoc """
  Role-Based Access Control (RBAC) for Hubs classrooms.
  
  Defines standard roles and their associated permissions for educational use.
  """

  import Bitwise

  @roles [:owner, :teacher, :student, :guest]

  @role_permissions %{
    owner: %{
      spawn_and_move_media: true,
      spawn_camera: true,
      spawn_drawing: true,
      pin_objects: true,
      spawn_emoji: true,
      fly: true,
      voice_chat: true,
      text_chat: true,
      manage_roles: true,
      manage_roster: true,
      manage_settings: true,
      kick_users: true,
      mute_users: true,
      close_room: true
    },
    teacher: %{
      spawn_and_move_media: true,
      spawn_camera: true,
      spawn_drawing: true,
      pin_objects: true,
      spawn_emoji: true,
      fly: true,
      voice_chat: true,
      text_chat: true,
      manage_roles: false,
      manage_roster: true,
      manage_settings: true,
      kick_users: true,
      mute_users: true,
      close_room: false
    },
    student: %{
      spawn_and_move_media: false,
      spawn_camera: false,
      spawn_drawing: true,
      pin_objects: false,
      spawn_emoji: true,
      fly: false,
      voice_chat: true,
      text_chat: true,
      manage_roles: false,
      manage_roster: false,
      manage_settings: false,
      kick_users: false,
      mute_users: false,
      close_room: false
    },
    guest: %{
      spawn_and_move_media: false,
      spawn_camera: false,
      spawn_drawing: false,
      pin_objects: false,
      spawn_emoji: false,
      fly: false,
      voice_chat: true,
      text_chat: true,
      manage_roles: false,
      manage_roster: false,
      manage_settings: false,
      kick_users: false,
      mute_users: false,
      close_room: false
    }
  }

  def roles, do: @roles

  def role_permissions(role) when is_atom(role), do: Map.get(@role_permissions, role, %{})

  def permissions_to_int(permissions) when is_map(permissions) do
    permissions
    |> Enum.reduce(0, fn
      {key, true}, acc ->
        bit = permission_bit(key)
        if bit, do: Bitwise.bor(acc, bit), else: acc
      _, acc ->
        acc
    end)
  end

  defp permission_bit(:spawn_and_move_media), do: 1 <<< 0
  defp permission_bit(:spawn_camera), do: 1 <<< 1
  defp permission_bit(:spawn_drawing), do: 1 <<< 2
  defp permission_bit(:pin_objects), do: 1 <<< 3
  defp permission_bit(:spawn_emoji), do: 1 <<< 4
  defp permission_bit(:fly), do: 1 <<< 5
  defp permission_bit(:voice_chat), do: 1 <<< 6
  defp permission_bit(:text_chat), do: 1 <<< 7
  defp permission_bit(:manage_roles), do: 1 <<< 8
  defp permission_bit(:manage_roster), do: 1 <<< 9
  defp permission_bit(:manage_settings), do: 1 <<< 10
  defp permission_bit(:kick_users), do: 1 <<< 11
  defp permission_bit(:mute_users), do: 1 <<< 12
  defp permission_bit(:close_room), do: 1 <<< 13
  defp permission_bit(_), do: nil

  def int_to_permissions(int) when is_integer(int) do
    @role_permissions
    |> Map.keys()
    |> Enum.flat_map(fn _ -> [:spawn_and_move_media, :spawn_camera, :spawn_drawing, :pin_objects,
                               :spawn_emoji, :fly, :voice_chat, :text_chat, :manage_roles,
                               :manage_roster, :manage_settings, :kick_users, :mute_users, :close_room] end)
    |> Enum.uniq()
    |> Enum.reduce(%{}, fn perm, acc ->
      bit = permission_bit(perm)
      if bit && Bitwise.band(int, bit) != 0 do
        Map.put(acc, perm, true)
      else
        acc
      end
    end)
  end

  def default_role, do: :student

  def role_can_assign?(assigner_role, target_role) do
    case assigner_role do
      :owner -> true
      :teacher -> target_role in [:student, :guest]
      _ -> false
    end
  end
end
