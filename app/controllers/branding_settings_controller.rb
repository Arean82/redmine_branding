# frozen_string_literal: true

# Administration → Branding
class BrandingSettingsController < ApplicationController
  layout 'admin'
  self.main_menu = false
  menu_item :redmine_branding

  before_action :require_admin

  def show
    @logo = RedmineBranding::Asset.new('logo')
    @favicon = RedmineBranding::Asset.new('favicon')
  end

  def upload
    kind = params[:kind]
    begin
      RedmineBranding::Asset.new(kind).store!(params[:file])
      flash[:notice] = l(:"notice_branding_#{kind}_saved")
    rescue RedmineBranding::Asset::InvalidUpload => e
      flash[:error] = l(:"error_branding_#{e.reason}", size: max_size_label(kind))
    end
    redirect_to branding_settings_path
  end

  def remove
    kind = params[:kind]
    RedmineBranding::Asset.new(kind).remove!
    flash[:notice] = l(:"notice_branding_#{kind}_removed")
    redirect_to branding_settings_path
  end

  def update_options
    link = params[:logo_link].to_s
    link = RedmineBranding::LogoLink::DEFAULT unless RedmineBranding::LogoLink::CHOICES.include?(link)
    url = params[:logo_link_url].to_s.strip

    if link == 'custom' && !RedmineBranding::LogoLink.valid_url?(url)
      flash[:error] = l(:error_branding_logo_link_url)
    else
      RedmineBranding::Settings.write(
        'login_logo' => params[:login_logo] == '1' ? '1' : '0',
        'logo_link' => link,
        'logo_link_url' => url,
        'show_version_footer' => params[:show_version_footer] == '1' ? '1' : '0',
        'override_footer' => params[:override_footer] == '1' ? '1' : '0',
        'custom_footer' => params[:custom_footer].to_s
      )
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to branding_settings_path
  end

  private

  def max_size_label(kind)
    ActiveSupport::NumberHelper.number_to_human_size(RedmineBranding::Asset.new(kind).max_size, locale: current_language)
  end
end
