defmodule Pleroma.Captcha.Service do
  @doc """
  Request new captcha from a captcha service.

  Returns:

  Service-specific data for using the newly created captcha
  """
  @callback new() :: map

  @doc """
  Validated the provided captcha solution.

  Arguments:
  * `token` the captcha is associated with
  * `captcha` solution of the captcha to validate

  Returns:

  `true` if captcha is valid, `false` if not
  """
  @callback validate(token :: String.t(), captcha :: String.t()) :: boolean

  @doc """
  This function is called periodically to clean up old captchas
  """
  @callback cleanup() :: :ok
end
