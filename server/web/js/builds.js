/*
 *  wi2wic -- Wiki To Wiki Converter
 *  Copyright (C) 2020 Stephane Carrez
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
    var BuildLog = /** @class */ (function () {
        function BuildLog(options, build) {
            var _this = this;
            this.logContainer = document.createElement('div');
            this.build = "";
            this.build = build;
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.logContainer);
            this.showAll = document.getElementById(options.btnShowAll);
            this.showInfo = document.getElementById(options.btnShowInfo);
            this.showWarn = document.getElementById(options.btnShowWarning);
            this.getBuildLogs(null);
            if (this.showAll) {
                this.showAll.addEventListener("click", function (event) {
                    _this.setMode(event, 'build-show-all');
                });
            }
            if (this.showInfo) {
                this.showInfo.addEventListener("click", function (event) {
                    _this.setMode(event, 'build-show-info');
                });
            }
            if (this.showWarn) {
                this.showWarn.addEventListener("click", function (event) {
                    _this.setMode(event, 'build-show-warning');
                });
            }
        }
        BuildLog.prototype.getBuildLogs = function (event) {
            var _this = this;
            if (this.build) {
                var build = this.build;
                var xmlhttp_1 = new XMLHttpRequest();
                xmlhttp_1.onload = function (evt) {
                    if (xmlhttp_1.status == 200 && _this.container) {
                        _this.updateResult(JSON.parse(xmlhttp_1.response));
                    }
                };
                xmlhttp_1.open("GET", "/porion/api/v1/builds/" + build + "/logs");
                xmlhttp_1.send();
            }
        };
        BuildLog.prototype.updateResult = function (content) {
            for (var _i = 0, content_1 = content; _i < content_1.length; _i++) {
                var log = content_1[_i];
                var div = document.createElement("div");
                var line = document.createElement("div");
                var content_2 = document.createElement("div");
                div.className = 'log-line log-level-' + log.level;
                line.className = 'log-line-number';
                line.textContent = log.number.toString();
                content_2.className = 'log-content';
                content_2.textContent = log.content;
                div.appendChild(line);
                div.appendChild(content_2);
                this.logContainer.appendChild(div);
            }
        };
        BuildLog.prototype.setMode = function (event, mode) {
            this.container.classList.remove('build-show-all', 'build-show-info', 'build-show-warning');
            this.container.classList.add(mode);
        };
        return BuildLog;
    }());
    Porion.BuildLog = BuildLog;
})(Porion || (Porion = {}));
