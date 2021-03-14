import * as chai from 'chai'
import { Assertion } from 'chai';

chai.use((_chai, utils) => {
    // utils.addProperty(Assertion.prototype, 'model', function () {
    //     this.assert(
    //         this._obj instanceof Model
    //         , 'expected #{this} to be a Model'
    //         , 'expected #{this} to not be a Model'
    //     );
    // });
})