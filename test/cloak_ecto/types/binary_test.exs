defmodule Cloak.Ecto.BinaryTest do
  use ExUnit.Case

  defmodule Field do
    use Cloak.Ecto.Binary, vault: Cloak.Ecto.TestVault
  end

  defmodule DelayedDecryptionField do
    use Cloak.Ecto.Binary, vault: Cloak.Ecto.TestVault, delay_decrypt: true
  end

  @invalid_types [%{}, 123, 123.33, []]

  describe ".type/0" do
    test "returns :binary" do
      assert Field.type() == :binary
    end
  end

  describe ".cast/1" do
    test "leaves nil unchanged" do
      assert {:ok, nil} == Field.cast(nil)
    end

    test "leaves binaries unchanged" do
      assert {:ok, "binary"} = Field.cast("binary")
    end

    test "returns :error on other types" do
      for invalid <- @invalid_types do
        assert :error == Field.cast(invalid)
      end
    end
  end

  describe "dump/1" do
    test "leaves nil unchanged" do
      assert {:ok, nil} == Field.dump(nil)
    end

    test "encrypts binaries" do
      {:ok, ciphertext} = Field.dump("value")
      assert ciphertext != "value"
    end

    test "returns :error on other types" do
      for invalid <- @invalid_types do
        assert :error == Field.dump(invalid)
      end
    end
  end

  describe ".load/1" do
    test "decrypts the ciphertext" do
      {:ok, ciphertext} = Field.dump("value")
      assert {:ok, "value"} = Field.load(ciphertext)
    end
  end

  describe "delay_decrypt" do
    test "delays decryption on DelayedDecryptionField.load if delay_decrypt specified" do
      {:ok, ciphertext} = DelayedDecryptionField.dump("value")
      assert {:ok, loaded_value} = DelayedDecryptionField.load(ciphertext)

      assert loaded_value == ciphertext
    end

    test "value can still be decrypted later" do
      {:ok, ciphertext} = DelayedDecryptionField.dump("value")

      decrypted_value = Cloak.Ecto.TestVault.decrypt!(ciphertext)

      assert decrypted_value == "value"
    end
  end
end
