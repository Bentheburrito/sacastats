import { InfantryModel } from '../models/planetside-model/infantry-model.js';
import { ModelType, PlanetsideModel } from '../models/planetside-model/planetside-model.js';

function init() {
  document.querySelectorAll('.' + PlanetsideModel.MODEL_CLASS).forEach((modelFigure) => {
    let modelFigureElement = modelFigure as HTMLElement;

    let type = modelFigureElement.dataset.modelType;
    let id = modelFigureElement.id;

    if (type === ModelType.INFANTRY) {
      let factionAlias = modelFigureElement.dataset.faction!;
      let headID = +modelFigureElement.dataset.headId!;
      let clazz = modelFigureElement.dataset.clazz!;

      new InfantryModel(id, factionAlias, headID, clazz).loadModels(); //must call loadModels() to render infantry model
    }
  });
}
init();
