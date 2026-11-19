# frozen_string_literal: true

# Dateien öffentlich (auch auf der Anmeldeseite), Einstellungen nur für Admins
kinds = /logo|favicon/

get 'branding/:kind', to: 'branding_assets#show', as: 'branding_asset', constraints: { kind: kinds }

get 'admin/branding', to: 'branding_settings#show', as: 'branding_settings'
post 'admin/branding/options', to: 'branding_settings#update_options', as: 'branding_settings_options'
post 'admin/branding/:kind', to: 'branding_settings#upload', as: 'branding_settings_asset', constraints: { kind: kinds }
delete 'admin/branding/:kind', to: 'branding_settings#remove', constraints: { kind: kinds }
