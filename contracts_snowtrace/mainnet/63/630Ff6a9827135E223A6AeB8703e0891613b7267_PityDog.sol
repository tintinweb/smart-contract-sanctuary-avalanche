//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./PetAccessControl.sol";

contract PityDog is PetAccessControl {    
    string constant public name = "Dog";

    function getPart(uint256 _partNumber) public view onlyOwner returns (string memory) {
        string[7] memory  parts = [
            //head
            '<g id="head"><g id="head_dog"><path d="M499.381,473.575c10.162,20.969 0.17,4.794 110.507,54.156c110.338,49.361 193.845,72.929 307.317,35.204c71.648,-23.82 138.864,-34.473 155.544,-55.777c23.229,-29.67 -46.458,-179.876 -31.94,-214.72c14.518,-34.843 27.584,-63.879 56.621,-113.241c29.036,-49.362 15.04,-50.117 -24.681,-78.398c-22.719,-16.175 -47.91,-19.687 -56.621,-21.777c-10.18,-2.444 -91.348,52.904 -110.222,75.146c-40.244,-16.783 -180.141,-25.785 -212.081,-8.363c-12.427,-28.107 -34.321,-92.103 -70.616,-90.651c-36.295,1.452 -98.607,48.548 -100.059,68.874c-1.452,20.325 47.271,88.561 38.56,117.597c-8.711,29.036 -72.492,210.98 -62.329,231.95Z" id="DogColor"/><path d="M598.589,192.028c6.954,-7.032 13.491,-19.129 44.787,-31.011c13.256,-5.033 -29.568,-59.861 -53.16,-63.491c-23.592,-3.629 -36.281,16.184 -27.208,48.792c9.074,32.608 20.834,60.623 35.581,45.71Z" style="fill:#deafb7;"/><path d="M1030.36,235.117c-6.028,-7.839 -22.054,-46.006 -53.349,-57.888c-13.256,-5.033 39.652,-44.401 63.244,-48.031c23.592,-3.629 38.566,15.422 29.492,48.031c-9.074,32.608 -26.162,75.085 -39.387,57.888Z" style="fill:#deafb7;"/><path d="M623.209,55.154c-0,-0 -105.399,30.024 -118.12,45.645c-12.72,15.621 -11.438,126.191 0,137.341c11.438,11.15 76.48,-100.349 93.204,-111.499c16.725,-11.15 35.309,7.433 49.246,22.3" id="DogColor"/><path d="M1016.13,79.022c34.667,4.877 101.567,49.71 111.787,66.783c10.221,17.073 -6.504,88.619 -24.158,117.423c-17.654,28.804 -64.112,-108.479 -78.979,-117.423c-14.866,-8.943 -39.314,1.255 -59.117,26.365" id="DogColor"/></g></g>',
            //body
            '<g id="belly"><g id="belly_dog"><path serif:id="belly dog" d="M857.916,453.453c-44.703,-3.734 -158.866,-0.956 -238.779,42.094c-44.503,23.975 -69.027,59.168 -95.024,103.786c-28.459,48.845 -74.556,146.379 -96.191,182.439c-24.254,40.422 -85.806,206.32 61.879,305.785c122.838,82.73 307.95,132.677 491.174,18.582c173.418,-107.987 47.975,-417.862 42.973,-506.806c-4.345,-77.258 -60.877,-137.097 -166.032,-145.88Z" id="DogColor"/><path d="M659.446,1089.63c21.106,18.97 40.228,44.678 40.228,44.678" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M652.989,1126.02c23.546,-15.841 53.142,-28.113 53.142,-28.113" style="fill:none;stroke:#05000e;stroke-width:24px;"/></g></g>',
            //right hand
            '<g id="paw_r"><g id="paw_r_dog"><path d="M552.518,528.444c-158.649,-12.679 -296.77,69.081 -288.302,150.985c3.492,33.78 67.564,35.264 136.544,27.83c59.585,-6.42 79.433,5.303 137.724,0c79.679,-7.247 104.066,-171.619 14.034,-178.815Z" id="DogColor"/><path id="bean1" d="M373.705,621.678c9.325,12.134 16.291,29.564 -2.604,39.592c-13.278,7.047 -34.274,7.689 -43.598,-4.445c-9.325,-12.134 -2.518,-29.042 7.698,-40.096c14.901,-16.122 29.18,-7.185 38.504,4.949Z" style="fill:#deafb7;"/><path id="bean2" d="M297.642,627.624c8.553,-3.066 17.825,0.94 20.693,8.94c2.867,8 -1.749,16.984 -10.302,20.05c-8.553,3.066 -17.826,-0.94 -20.693,-8.94c-2.868,-8 1.748,-16.984 10.302,-20.05Z" style="fill:#deafb7;"/><path id="bean3" d="M296.489,665.824c5.73,-5.256 14.314,-5.236 19.158,0.044c4.843,5.28 4.124,13.834 -1.606,19.09c-5.73,5.256 -14.314,5.237 -19.157,-0.044c-4.844,-5.28 -4.125,-13.834 1.605,-19.09Z" style="fill:#deafb7;"/><path id="bean4" d="M332.803,672.318c6.097,-4.919 14.691,-4.395 19.18,1.169c4.489,5.564 3.184,14.074 -2.912,18.993c-6.097,4.919 -14.691,4.395 -19.18,-1.169c-4.49,-5.564 -3.185,-14.074 2.912,-18.993Z" style="fill:#deafb7;"/></g></g>',
            //left hand
            '<g id="paw_l"><g id="paw_l_dog"><path d="M1021.4,581.217c64.287,-14.286 153.821,26.739 206.938,81.86c45.852,47.583 88.245,111.521 80.986,181.208c-7.259,69.687 -75.879,45.488 -99.569,24.158c-40.047,-36.056 -116.83,-77.243 -188.355,-92.393c-137.632,-29.152 -61.531,-181.16 0,-194.833Z" id="DogColor"/><path d="M1251.19,886.62c-4.645,-17.654 5.575,-17.654 -11.149,-50.175" style="fill:none;stroke:#000;stroke-width:24px;"/><path d="M1300.44,862.462c-2.787,-21.371 -11.15,-32.521 -29.733,-50.175" style="fill:none;stroke:#000;stroke-width:24px;"/></g></g>',
            //left leg
            '<g id="leg_l"><g id="leg_l_dog"><path d="M876.496,1192.52c68.882,46.6 165.831,125.402 209.582,100.446c41.006,-23.391 26.462,-110.542 0,-167.618c-30.687,-66.189 -101.2,-166.229 -192.292,-99.89c-72.512,52.807 -67.019,133.421 -17.29,167.062Z" id="DogColor"/><path d="M1065.54,1293.95c-1.982,-23.164 -12.884,-34.066 -29.733,-50.915" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1106.84,1268.52c-6.397,-18.034 -14.995,-37.288 -27.655,-50.956" style="fill:none;stroke:#05000e;stroke-width:24px;"/></g></g>',
            //right leg
            '<g id="leg_r"><g id="leg_r_dog"><path d="M445.214,1086.06c-50.885,8.801 -139.598,38.426 -184.471,36.585c-47.813,-1.961 -50.418,-83.97 0,-150.742c34.902,-46.223 115.856,-133.125 184.471,-63.336c40.289,40.978 91.978,161.585 0,177.493Z" id="DogColor"/><path d="M286.741,1070.31c-6.371,12.035 -17.698,30.441 -8.495,44.6" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M266.919,1040.58c-11.327,2.832 -34.688,41.768 -35.396,55.218" style="fill:none;stroke:#05000e;stroke-width:24px;"/></g></g>',
            //add
            '<g id="add"><g id="add_dog"><path d="M954.005,946.671c-10.554,25.8 119.91,111.139 252.671,75.055c159.626,-43.386 205.965,-172.715 161.315,-283.152c-49.42,-122.239 -220.114,-146.603 -286.555,-9.357c-35.081,72.466 26.01,74.053 58.044,53.233c42.37,-27.538 128.86,53.779 67.196,121.673c-91.093,100.298 -242.117,16.748 -252.671,42.548Z" id="DogColor"/><path d="M1265.51,667.484c-1.459,0.042 -4.424,-4.738 -5.257,-5.712c-5.305,-6.204 -10.712,-12.3 -16.116,-18.411c-18.029,-20.383 -37.243,-39.968 -60.702,-53.549" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1209.15,665.902c-1.161,0.033 -5.275,-4.657 -6.272,-5.442c-5.791,-4.559 -12.121,-8.31 -18.475,-11.936c-19.729,-11.259 -37.836,-18.485 -60.478,-17.829" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1149.68,690.115c-4.246,-4.173 -12.888,-6.055 -18.223,-7.927c-18.741,-6.574 -37.432,-8.059 -57.028,-6.563" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1118.33,726.367c-16.265,-5.123 -33.612,-11.14 -50.844,-9.493" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1303.01,689.916c-0.896,-30.969 -13.744,-61.144 -24.768,-89.433" style="fill:none;stroke:#05000e;stroke-width:24px;"/></g></g>'
        ];

        return parts[_partNumber];
    }

    function getColor(uint256 _colorId) public view onlyOwner returns (string memory, string memory) {
        string[10] memory colors = [
            '36afdc',
            '6c96f0',
            '2865b6',
            '7ea0c2',
            '12a1b8',
            '7ebce5',
            '4a70e8',
            '7465f5',
            '2b53e3',
            '3d89ab'
        ];

        return (colors[_colorId], "DogColor");
    }
}