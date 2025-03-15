// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import GenericFormController from "./generic_form_controller"
application.register("generic-form", GenericFormController)
eagerLoadControllersFrom("controllers", application)
