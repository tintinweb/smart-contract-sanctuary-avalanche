//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./PetAccessControl.sol";

contract PityWoodoo is PetAccessControl {
    string constant public name = "Woodoo";

    function getPart(uint256 _partNumber) public view onlyOwner returns (string memory) {
        string[7] memory parts = [
            //head
            '<g id="head"><g id="head_woodoo"><path d="M793.574,118.785c184.43,-3.004 279.328,64.017 315.333,211.97c17.649,72.523 9.888,146.117 -77.879,183.183c-67.778,28.624 -161.998,67.836 -237.454,67.836c-161.859,-0 -302.274,-114.692 -271.199,-251.019c37.166,-163.052 109.362,-209.334 271.199,-211.97Z" id="WoodooColor"/><g id="sew"><path d="M1009.91,221.601c32.928,54.017 55.99,152.086 -2.937,255.529" style="fill:none;stroke:#000;stroke-width:15.27px;"/><path d="M1002,266.002l44.478,-10.876" style="fill:none;stroke:#000;stroke-width:15.27px;"/><path d="M1010.53,326.247l47.798,-6.763" style="fill:none;stroke:#000;stroke-width:15.27px;"/><path d="M1013.63,371.431l50.338,-3.961" style="fill:none;stroke:#000;stroke-width:15.27px;"/><path d="M1015.98,409.436l39.272,6.989" style="fill:none;stroke:#000;stroke-width:15.27px;"/><path d="M998.291,446.222l35.485,16.886" style="fill:none;stroke:#000;stroke-width:15.27px;"/></g></g></g>',
            //body
            '<g id="belly"><g id="belly_woodoo"><path serif:id="belly_woodoo" d="M857.916,453.453c-44.703,-3.734 -158.866,-0.956 -238.779,42.094c-44.503,23.975 -157.786,214.327 -191.215,287.677c-28.414,62.344 -159.697,219.777 -0,298.526c67.668,33.368 482.083,163.402 573.378,75.203c87.254,-84.295 56.686,-484.646 31.359,-559.072c-24.929,-73.254 -69.588,-135.645 -174.743,-144.428Z" id="WoodooColor"/><g><path d="M985.098,766.461c0.265,73.345 -13.146,138.349 -33.101,239.937" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/><path d="M963.348,803.551l36.201,-0.831" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/><path d="M959.341,841.304l36.744,2.414" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/><path d="M953.242,887.974l39.621,4.785" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/><path d="M942.255,922.712l47.661,16.915" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/><path d="M936.479,960.911l41.472,26.793" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/></g><g><path d="M728.018,1103.87c-45.482,0.822 -81.122,-10.693 -137.163,-27.789" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/><path d="M712.071,1084.45l-4.61,36.533" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/><path d="M665.851,1075.57l-7.151,39.263" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/><path d="M627.187,1067.16l-14.858,35.048" style="fill:none;stroke:#2f2217;stroke-width:15.27px;"/></g></g></g>',
            //right hand
            '<g id="paw_r"><g id="paw_r_woodoo"><path d="M582.895,528.953c-40.42,-28.067 -172.465,-18.743 -253.716,41.89c-79.001,58.953 -90.097,135.864 -52.617,162.725c29.136,20.881 83.441,-3.249 117.597,-18.583c60.855,-27.321 64.98,-0.224 106.273,0c53.427,0.291 138.358,-147.22 82.463,-186.032Z" id="WoodooColor"/><path d="M317.213,656.042c-0,-0 -22.939,52.265 15.099,45.296c38.037,-6.969 58.943,-45.296 58.943,-45.296" id="WoodooColor"/><path d="M370.636,601.631c38.087,-27.899 82.727,-35.76 112.958,-37.86" style="fill:none;stroke:#000;stroke-width:15px;"/><path d="M390.529,570.96c9.524,7.343 11.708,14.041 13.117,24.864" style="fill:none;stroke:#000;stroke-width:15px;"/><path d="M445.113,552.411c9.096,11.625 8.248,20.192 8.687,30.508" style="fill:none;stroke:#000;stroke-width:15px;"/></g></g>',
            //left hand
            '<g id="paw_l"><g id="paw_l_woodoo"><path d="M1036.64,590.371c45.44,-4.259 115.794,19.976 183.334,83.856c67.54,63.88 93.092,122.475 77.122,168.933c-15.97,46.458 -85.077,26.656 -102.498,9.292c-9.989,22.59 -30.547,36.586 -51.975,19.57c-32.038,-25.439 -16.609,-59.64 -64.867,-79.617c-53.405,-22.107 -80.954,-17.422 -108.538,-43.554c-27.585,-26.133 -60.318,-146.508 67.422,-158.48Z" id="WoodooColor"/><path d="M1111.43,764.851c-32.46,-34.283 -74.964,-50.03 -104.327,-57.522" style="fill:none;stroke:#000;stroke-width:15px;"/><path d="M1097.36,731.107c-10.688,5.515 -14.039,11.711 -17.368,22.106" style="fill:none;stroke:#000;stroke-width:15px;"/><path d="M1047,703.061c-11.035,9.804 -11.739,18.383 -14.023,28.453" style="fill:none;stroke:#000;stroke-width:15px;"/></g></g>',
            //left leg
            '<g id="leg_l"><g id="leg_l_woodoo"><path d="M871.54,1198.46c45.402,85.178 149.332,133.153 193.328,108.632c33.077,-18.435 32.806,-120.71 21.21,-175.804c-15.025,-71.393 -101.2,-172.176 -192.292,-105.837c-72.512,52.807 -42.776,134.493 -22.246,173.009Z" id="WoodooColor"/><path d="M923.474,1185.43c23.593,40.895 61.266,66.098 88.08,80.216" style="fill:none;stroke:#000;stroke-width:15px;"/><path d="M968.694,1258.51c5.109,-13.322 12.483,-18.407 25.283,-24.318" style="fill:none;stroke:#000;stroke-width:15px;"/><path d="M929.49,1226c5.978,-16.43 15.879,-21.424 26.74,-28.814" style="fill:none;stroke:#000;stroke-width:15px;"/></g></g>',
            //right leg
            '<g id="leg_r"><g id="leg_r_woodoo"><path d="M445.214,1097.12c-34.293,26.499 -125.219,70.503 -184.471,58.707c-46.932,-9.343 -34.844,-127.773 0,-183.926c30.539,-49.215 113.644,-114.32 184.471,-63.336c46.64,33.573 73.861,131.48 0,188.555Z" id="WoodooColor"/><path d="M416.615,1053c-32.26,34.472 -74.671,50.466 -103.99,58.129" style="fill:none;stroke:#000;stroke-width:15px;"/><path d="M340.603,1079.49c10.08,10.099 11.714,18.906 11.889,33.004" style="fill:none;stroke:#000;stroke-width:15px;"/><path d="M386.282,1056.96c12.191,10.456 13.091,19.572 15.738,30.277" style="fill:none;stroke:#000;stroke-width:15px;"/></g></g>',
            //add
            '<g id="add"><g id="add_woodoo"><path d="M967.466,571.057l239.252,-77.978" style="fill:none;stroke:#05000e;stroke-width:24px;"/><ellipse cx="1231.99" cy="486.727" rx="29.242" ry="31.9" id="WoodooColor"/><path d="M937.647,584.128l201.961,-150.112" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1151.38,389.707c15.298,-5.14 32.271,4.237 37.878,20.927c5.607,16.689 -2.261,34.412 -17.56,39.552c-15.299,5.139 -32.272,-4.238 -37.879,-20.927c-5.607,-16.69 2.262,-34.412 17.561,-39.552Z" id="WoodooColor"/><path d="M991.116,902.625l206.685,52.597" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1233.24,939.282c11.558,7.316 14.463,23.491 6.483,36.1c-7.981,12.609 -23.843,16.907 -35.401,9.591c-11.558,-7.315 -14.463,-23.49 -6.483,-36.099c7.98,-12.609 23.843,-16.907 35.401,-9.592Z" id="WoodooColor"/><path d="M979.903,662.474l207.632,-48.728" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1211.62,583.251c13.63,1.155 23.672,14.164 22.412,29.033c-1.26,14.869 -13.349,26.002 -26.979,24.847c-13.629,-1.155 -23.671,-14.165 -22.411,-29.033c1.26,-14.869 13.349,-26.002 26.978,-24.847Z" id="WoodooColor"/><path d="M993.802,961.581l150.525,80.523" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1174.92,1036.52c7.579,7.902 6.733,21.029 -1.887,29.297c-8.62,8.267 -21.771,8.564 -29.35,0.662c-7.578,-7.902 -6.732,-21.029 1.888,-29.296c8.62,-8.268 21.771,-8.565 29.349,-0.663Z" id="WoodooColor"/><path d="M487.758,835.832l-170.691,2.507" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M293.013,858.054c-10.459,-3.239 -16.08,-15.132 -12.546,-26.541c3.534,-11.409 14.894,-18.042 25.352,-14.802c10.458,3.239 16.08,15.132 12.546,26.541c-3.534,11.409 -14.894,18.042 -25.352,14.802Z" id="WoodooColor"/><path d="M621.477,559.742l-145.851,-88.708" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M444.769,474.925c-7.131,-8.308 -5.562,-21.369 3.501,-29.147c9.064,-7.779 22.211,-7.35 29.342,0.958c7.131,8.308 5.562,21.369 -3.502,29.148c-9.063,7.779 -22.211,7.349 -29.341,-0.959Z" id="WoodooColor"/></g></g>'
        ];

        return parts[_partNumber];
    }

    function getColor(uint256 _colorId) public view onlyOwner returns (string memory, string memory) {
        string[10] memory colors = [
            'e6872c',
            'e9a840',
            'd3a800',
            'b07800',
            '937004',
            'a88054',
            'e3c477',
            'f9b100',
            'ffe82a',
            'dfae7a'
        ];

        return (colors[_colorId], "WoodooColor");
    }
}