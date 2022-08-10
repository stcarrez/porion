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
    var BarGraph = /** @class */ (function () {
        function BarGraph(container, legend, series, ticks) {
            var div = document.getElementById(container);
            $.plot($(div), series, {
                series: {
                    bars: {
                        show: true,
                        horizontal: true,
                        align: "center"
                    }
                },
                legend: {
                    show: false,
                    backgroundOpacity: 0.5
                },
                xaxis: {
                    ticks: [],
                    color: "#993D00"
                },
                yaxis: {
                    ticks: ticks,
                    tickSize: [10, "px"],
                    font: { size: 18, style: "normal" },
                    show: true,
                    color: "#993D00",
                    tickColor: "#00ff00"
                }
            });
        }
        return BarGraph;
    }());
    Porion.BarGraph = BarGraph;
    var TestChart = /** @class */ (function () {
        function TestChart(options, project) {
            this.graphContainer = document.createElement('div');
            this.project = "";
            this.container = document.getElementById(options.container);
            this.container.appendChild(this.graphContainer);
            this.project = project;
            this.getData(null);
        }
        TestChart.prototype.getData = function (event) {
            var _this = this;
            if (this.project) {
                var project = this.project;
                var xmlhttp_1 = new XMLHttpRequest();
                xmlhttp_1.onload = function (evt) {
                    if (xmlhttp_1.status == 200 && _this.container) {
                        _this.updateData(JSON.parse(xmlhttp_1.response));
                    }
                };
                xmlhttp_1.open("GET", "/porion/api/v1/projects/" + project + "/tests");
                xmlhttp_1.send();
            }
        };
        TestChart.prototype.updateData = function (content) {
            var pass = new Array();
            var fail = new Array();
            var timeout = new Array();
            var duration = new Array();
            var first_build = 10000;
            var last_build = 0;
            for (var _i = 0, _a = content.tests; _i < _a.length; _i++) {
                var test = _a[_i];
                if (test.build_status == "BUILD_PASS") {
                    if (test.build_number < first_build) {
                        first_build = test.build_number;
                    }
                    if (test.build_number > last_build) {
                        last_build = test.build_number;
                    }
                    timeout.push([test.build_number, test.timeout_count]);
                    fail.push([test.build_number, test.fail_count + test.timeout_count]);
                    pass.push([test.build_number, test.pass_count + test.fail_count + test.timeout_count]);
                    duration.push([test.build_number, test.test_duration]);
                }
            }
            $.plot($(this.container), [timeout, fail, pass], {
                colors: ["red", "green", "blue"],
                series: {
                    lines: {
                        show: true,
                        fill: true
                    },
                    points: {
                        show: true
                    },
                    clickable: true,
                    hoverable: true
                },
                grid: {
                    hoverable: true,
                    clickable: true
                },
                xaxis: {
                    color: "#993D00",
                    show: true
                },
                yaxis: {
                    show: true
                },
                legend: {
                    show: false
                }
            });
        };
        return TestChart;
    }());
    Porion.TestChart = TestChart;
    /*    export class PieChart {
    
            constructor(container: string, legend: string, series: jquery.flot.dataSeries[], ticks: any) {
                var div : HTMLElement = document.getElementById(container);
                $.plot($(div), series, {
                    series: {
                        pie: {
                            show: true,
                            startAngle: 1.0, radius: 1.0, innerRadius: 0.5, tilt: 1.0, offset: { top: 0, left: 0 },
                            label: { show: true }
                        }
                    },
                    legend: {
                        show: false
                    }
                });
            }
        }*/
})(Porion || (Porion = {}));
