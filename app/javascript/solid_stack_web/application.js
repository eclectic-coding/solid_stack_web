import "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"
import SelectionController from "solid_stack_web/selection_controller"

const application = Application.start()
application.register("selection", SelectionController)