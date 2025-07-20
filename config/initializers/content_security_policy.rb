# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Rails.application.configure do
#   config.content_security_policy do |policy|
#     policy.default_src :self, :https
#     policy.font_src    :self, :https, :data
#     policy.img_src     :self, :https, :data
#     policy.object_src  :none
#     policy.script_src  :self, :https
#     policy.style_src   :self, :https
#     # Specify URI for violation reports
#     # policy.report_uri "/csp-violation-report-endpoint"
#   end
#
#   # Generate session nonces for permitted importmap and inline scripts
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w(script-src)
#
#   # Report violations without enforcing the policy.
#   # config.content_security_policy_report_only = true
# end

Rails.application.config.content_security_policy do |policy|
  asset_host = Rails.application.config.action_controller.asset_host.presence

  policy.font_src(*[:self, :https, :data, asset_host].compact)
  policy.img_src(*[:self, :https, :data, :blob, asset_host].compact)
  policy.object_src :none
  policy.style_src(*[:self, :https, :unsafe_inline, asset_host].compact)
  policy.script_src(*[:self, :https, :unsafe_eval, :unsafe_inline, asset_host].compact)
  policy.connect_src(*[:self, :https, asset_host].compact)
  # policy.frame_src :self, "https://secure.pay1.de", "https://secure.livechatinc.com"
  policy.default_src :self, :https

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"

  case Rails.env
  when "production"
    # policy.frame_src(*policy.frame_src, "https://wizardiframe.channelconnector.com")
  when "development"
    vite = ViteRuby.config.host_with_port

    # Allow @vite/client to hot reload style changes in development
    policy.style_src(*policy.style_src, :unsafe_inline)
    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src(*policy.script_src, :unsafe_eval, "http://#{vite}")
    # Allow @vite/client to hot reload changes in development
    policy.connect_src(*policy.connect_src, "ws://#{vite}")
  when "test"
    # You may need to enable this in production as well depending on your setup.
    policy.script_src(*policy.script_src, :blob)
  end
end
