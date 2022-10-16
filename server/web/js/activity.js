/*
 *  activity -- Display graphs for global project and build activities
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
    var ActivityChart = /** @class */ (function () {
        function ActivityChart(options) {
            this.heatmapGraphContainer = document.createElement('div');
            this.heatmapContainer = document.getElementById(options.container);
            if (this.heatmapContainer) {
                this.heatmapContainer.appendChild(this.heatmapGraphContainer);
                this.heatmapGraphContainer.className = 'graph-view';
                this.getData(null);
            }
        }
        ActivityChart.prototype.getData = function (event) {
            var _this = this;
            var xmlhttp = new XMLHttpRequest();
            xmlhttp.onload = function (evt) {
                if (xmlhttp.status == 200 && _this.heatmapContainer) {
                    _this.updateData(JSON.parse(xmlhttp.response));
                }
            };
            xmlhttp.open("GET", "/porion/api/v1/activity/global");
            xmlhttp.send();
        };
        ActivityChart.prototype.updateData = function (content) {
            var datapoints = {};
            for (var _i = 0, content_1 = content; _i < content_1.length; _i++) {
                var usage = content_1[_i];
                datapoints[String(usage.timestamp)] = usage.count;
            }
            var data = {
                dataPoints: datapoints
            };
            var chart = new Frappe.Chart(this.heatmapGraphContainer, {
                animate: 0,
                data: data,
                type: 'heatmap',
                height: 150,
                valuesOverPoints: 1,
                discreteDomains: 0,
                colors: ['#535253', '#c0ddf9', '#73b3f3', '#3886e1', '#17459e']
            });
        };
        return ActivityChart;
    }());
    Porion.ActivityChart = ActivityChart;
})(Porion || (Porion = {}));
