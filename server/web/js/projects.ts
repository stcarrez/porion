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
namespace Porion {
    export class BarGraph {

        constructor(container: string, legend: string, series: jquery.flot.dataSeries[], ticks: any) {
            var div : HTMLElement = document.getElementById(container);
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
                    tickSize: [ 10, "px" ],
                    font: { size: 18, style: "normal" },
                    show: true,
                    color: "#993D00",
                    tickColor: "#00ff00"
                }
            });
        }
    }

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
}
