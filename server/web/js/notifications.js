/*
 *  notifications -- Notifications interface
 *  Copyright (C) 2022 Stephane Carrez
 *  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
var Porion;
(function (Porion) {
    var Notifications = /** @class */ (function () {
        function Notifications(options, project) {
            var _this = this;
            this.container = document.getElementById(options.container);
            this.projectSelector = document.getElementById(options.projectSelector);
            if (this.projectSelector) {
                this.projectSelector.addEventListener("change", function (event) {
                    _this.onSelectProject(event);
                });
            }
        }
        Notifications.prototype.onSelectProject = function (event) {
            var _this = this;
            var xmlhttp = new XMLHttpRequest();
            var selector = event.target;
            if (!selector) {
                return;
            }
            xmlhttp.onload = function (evt) {
                if (xmlhttp.status == 200 && _this.container) {
                }
            };
            xmlhttp.open("POST", "/porion/api/v1/subscribers");
            xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            xmlhttp.send("project=" + selector.value);
        };
        return Notifications;
    }());
    Porion.Notifications = Notifications;
})(Porion || (Porion = {}));
