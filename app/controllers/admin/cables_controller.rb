# coding: utf-8
class Admin::CablesController < ApplicationController
  include Admin::ControllerExtensions

  expose(:inquiry)    { Inquiry.find params[:inquiry_id] }
  expose(:cable_form) { CableForm.from_cable cable }

  expose :cable do
    if id = params[:id].presence
      inquiry.cables.find id
    else
      inquiry.cables.build
    end
  end

  def create
    cable_form.attributes = cable_params
    if cable_form.valid?
      cable_form.save
      flash["success"] = "Meldung gespeichert."
    else
      flash["error"] = "Meldung konnte nicht gespeichert werden: #{cable_form.errors.full_messages.to_sentence}"
    end
    redirect_to redirect_target
  end

  def destroy
    cable.destroy
    flash["success"] = "Meldung gelöscht."
    redirect_to redirect_target
  end

private

  def cable_params
    params.require(:cable).permit(:contact_id, :inquiry_id, :text)
  end

  def redirect_target
    [:edit, :admin, inquiry.booking || inquiry, anchor: "communication"]
  end

end
