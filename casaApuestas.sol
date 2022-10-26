pragma solidity ^0.6.0;

contract casaApuestas{
    address public anfitrion;
    enum Estado {Creada, Registrada, Terminada}
    uint public totalCarreras;
    mapping(uint => Carrera) public carreras; //carreras existentes
    mapping(uint => Caballo) public caballos; //caballos existentes
    mapping(uint => uint[]) public competencias; //caballos registrados en una carrera determinada
    mapping(uint => address[]) public apostadores; //apostadores registrados en una carrera determinada

    event CarreraInsertada(uint codigo, string nombre, Estado estadoCarrera);
    event CarreraRegistrada(uint codigo, string nombre, Estado estadoCarrera);
    event CarreraTerminada(uint codigo, string nombre, Estado estadoCarrera);
    event CaballoInsertado(uint codigo, string nombre);
    event CaballoGanador(uint codCarrera, uint codCaballo);
    event ApuestaRealizada(uint codCarrera, uint codCaballo, address apostador, uint monto);

    struct Carrera{
        uint codigo;
        string nombre;
        Estado estadoCarrera;
        uint montoTotal; //monto total de las apuestas realizadas en la carrera
        uint numeroCaballos;
        uint caballoGanador;
        mapping(address => Apuesta) apuestas; //usuarios con sus respectivas apuestas realizadas en la carrera
    }

    struct Caballo{
        uint codigo;
        string nombre;
    }

    struct Apuesta{
        uint monto;
        uint codCaballo;
        bool creada;
        uint proporcion;
        uint dineroTransferido;
    }

    constructor() public {
        anfitrion = msg.sender;
    }

    //se verifica que el invocador sea el anfitrion
    modifier isAnfitrion(){
        require(msg.sender == anfitrion, "El invocador debe ser el anfitrion");
        _;
    }
    //se verifica que el invocador no sea el anfitrion
    modifier isNotAnfitrion(){
        require(msg.sender != anfitrion, "El invocador debe ser un usuario diferente al anfitrion");
        _;
    }
    //se verifica que la carrera se encuentre en un estado determinado 
    modifier estadoAct(uint _codCarrera, Estado _estado){
        require(carreras[_codCarrera].estadoCarrera == _estado, "La carrera no cumple con el estado requerido");
        _;
    }
    //se verifica que la carrera posea 5 o menos caballos
    modifier tamanoMax(uint _codCarrera){
        require(competencias[_codCarrera].length < 5, "La carrera ya cuenta con 5 caballos");
        _;
    }
    //se verifica que la carrera tenga mínimo 2 caballos registrados
    modifier tamanoMin(uint _codCarrera){
        require(competencias[_codCarrera].length >= 2, "La carrera debe contar con al menos 2 caballos");
        _;
    }
    //se verifica que el caballo exista
    modifier caballoExiste(uint _codCaballo){
        require(bytes(caballos[_codCaballo].nombre).length != 0, "El caballo ingresado no existe");
        _;
    }
    //se verifica que la carrera exista
    modifier carreraExiste(uint _codCarrera){
        require(bytes(carreras[_codCarrera].nombre).length != 0, "La carrera ingresada no existe");
        _;
    }
    //se verifica que no se ingrese un caballo repetido
    modifier caballoRepetido(uint _codCaballo){
        require(bytes(caballos[_codCaballo].nombre).length == 0, "Ya existe un caballo con este código");
        _;
    }
    //se verifica que no se ingrese una carrera repetida
    modifier carreraRepetida(uint _codCarrera){
        require(bytes(carreras[_codCarrera].nombre).length == 0, "Ya existe una carrera con este código");
        _;
    }
    //se verifica que no se vuelva a registrar un caballo en una carrera determinada
    modifier caballoRepCarrera(uint _codCarrera, uint _codCaballo){
        uint cantCaballos = competencias[_codCarrera].length;
        bool caballoRep = false;
        for(uint i = 0; i < cantCaballos; i++){
            if(competencias[_codCarrera][i] == _codCaballo){
                caballoRep = true;
                break;
            }
        }
        require(!caballoRep, "Este caballo ya se encuentra registrado en esta carrera");
        _;
    }
    //se verifica que un caballo dado esté registrado en una carrera determinada
    modifier caballoEnCarrera(uint _codCarrera, uint _codCaballo){
        uint cantCaballos = competencias[_codCarrera].length;
        bool cabEncontrado = false;
        for(uint i = 0; i < cantCaballos; i++){
            if(competencias[_codCarrera][i] == _codCaballo){
                cabEncontrado = true;
                break;
            }
        }
        require(cabEncontrado, "Este caballo no se encuentra registrado en esta carrera");
        _;
    }
    //se verifica que la apuesta realizada sea mayor que cero
    modifier apuestaPositiva(uint _monto){
        require(_monto > 0, "El monto de la apuesta debe ser mayor a 0");
        _;
    }
    //se verifica que en determinada carrera haya apostadores
    modifier cantApostadores(uint _codCarrera){
        require(apostadores[_codCarrera].length > 0, "La carrera ingresada no tiene apostadores");
        _;
    }
    //crear una carrera
    function crearCarrera(uint _codigo, string memory _nombre) public 
    isAnfitrion
    carreraRepetida(_codigo){
        carreras[_codigo] = Carrera(_codigo, _nombre, Estado.Creada, 0, 0, 0);
        totalCarreras += 1;
        emit CarreraInsertada(carreras[_codigo].codigo, carreras[_codigo].nombre, carreras[_codigo].estadoCarrera);
    }
    //registrar un caballo 
    function registrarCaballo(uint _codigo, string memory _nombre) public 
    isAnfitrion
    caballoRepetido(_codigo){
        caballos[_codigo] = Caballo(_codigo, _nombre);
        emit CaballoInsertado(caballos[_codigo].codigo, caballos[_codigo].nombre);
    }
    //registrar un caballo en una carrera
    function registrarEnCarrera(uint _codCaballo, uint _codCarrera) public 
    isAnfitrion
    estadoAct(_codCarrera, Estado.Creada)
    tamanoMax(_codCarrera)
    caballoExiste(_codCaballo)
    carreraExiste(_codCarrera)
    caballoRepCarrera(_codCarrera, _codCaballo){
        competencias[_codCarrera].push(_codCaballo);
        carreras[_codCarrera].numeroCaballos += 1;
    }
    //Registrar carrera
    function registrarCarrera(uint _codCarrera) public 
    isAnfitrion
    estadoAct(_codCarrera, Estado.Creada)
    carreraExiste(_codCarrera)
    tamanoMin(_codCarrera){
        carreras[_codCarrera].estadoCarrera = Estado.Registrada;
        emit CarreraRegistrada(carreras[_codCarrera].codigo, carreras[_codCarrera].nombre, carreras[_codCarrera].estadoCarrera);
    }
    //realizar apuesta por un caballo en una determinada carrera
    function apostar(uint _codCaballo, uint _codCarrera) payable public 
    isNotAnfitrion
    estadoAct(_codCarrera, Estado.Registrada)
    caballoExiste(_codCaballo)
    carreraExiste(_codCarrera)
    caballoEnCarrera(_codCarrera, _codCaballo)
    apuestaPositiva(msg.value){
        uint montoApuesta = msg.value;
        address apostador = msg.sender;
        //Se comprueba si el ususario tiene apuestas 
        if(carreras[_codCarrera].apuestas[apostador].creada){
            //Se verifica que el usuario no apueste por otro caballo
            require(carreras[_codCarrera].apuestas[apostador].codCaballo == _codCaballo, "Solo se puede apostar por un caballo dentro de esta carrera");
            carreras[_codCarrera].apuestas[apostador].monto += montoApuesta;
            carreras[_codCarrera].montoTotal += montoApuesta;
        } else{
            //Si el usuario no tiene apuestas previas se le crea una por primera vez
            carreras[_codCarrera].apuestas[apostador] = Apuesta(montoApuesta, _codCaballo, true, 0, 0);
            carreras[_codCarrera].montoTotal += montoApuesta;
            apostadores[_codCarrera].push(apostador); // Apostadores por cada carrera
        }
        emit ApuestaRealizada(_codCarrera, _codCaballo, apostador, montoApuesta);
    }
    //generar número aleatorio para elegir el caballo ganador
    function generarAleatorio(uint modulo) internal returns(uint){
        uint randNonce = 0;
        randNonce ++; 
        uint numero = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % modulo;
        return (numero);
    }
    //dar por terminada una carrera
    function terminarCarrera(uint _codCarrera) payable public
    isAnfitrion
    carreraExiste(_codCarrera)
    estadoAct(_codCarrera, Estado.Registrada){
        uint indiceCaballoGanador = generarAleatorio(carreras[_codCarrera].numeroCaballos);  // Se obtiene le indice del caballo ganador (0,N-1)
        uint apostadoPorGanadores = 0; // El monto que apostaron unicamente los que ganaron (caballo ganador)
        carreras[_codCarrera].caballoGanador = competencias[_codCarrera][indiceCaballoGanador];
        emit CaballoGanador(_codCarrera, carreras[_codCarrera].caballoGanador);
        // For para calcular el total apostado por los ganadores
        for (uint i = 0; i < apostadores[_codCarrera].length; i++) {  // Total de apostadores para esta carrera
            address direccion = apostadores[_codCarrera][i]; // Dirección de los apostadores vinculados a una carrera y se obtiene la direccion con el indice

            if (carreras[_codCarrera].apuestas[direccion].codCaballo == competencias[_codCarrera][indiceCaballoGanador]){
                apostadoPorGanadores += carreras[_codCarrera].apuestas[direccion].monto;
            }
        }  

        if (apostadoPorGanadores != 0){
            // For para calcular la comisión de cada ganador
            for (uint i = 0; i < apostadores[_codCarrera].length; i++) {
                address direccion = apostadores[_codCarrera][i];
                if (carreras[_codCarrera].apuestas[direccion].codCaballo == competencias[_codCarrera][indiceCaballoGanador]){
                    carreras[_codCarrera].apuestas[direccion].proporcion = (carreras[_codCarrera].apuestas[direccion].monto / apostadoPorGanadores); // Se le asigna la proporcion al apostador
                    payable(direccion).transfer(((carreras[_codCarrera].apuestas[direccion].monto * 10000) / apostadoPorGanadores) * (carreras[_codCarrera].montoTotal - (carreras[_codCarrera].montoTotal / 4)) /10000);
                    carreras[_codCarrera].apuestas[direccion].dineroTransferido = ((carreras[_codCarrera].apuestas[direccion].monto * 10000) / apostadoPorGanadores) * (carreras[_codCarrera].montoTotal - (carreras[_codCarrera].montoTotal / 4)) /10000;
                }
            } 
            msg.sender.transfer(carreras[_codCarrera].montoTotal / 4);
        }else{
            msg.sender.transfer(carreras[_codCarrera].montoTotal);
        }
        carreras[_codCarrera].estadoCarrera = Estado.Terminada;
        emit CarreraTerminada(carreras[_codCarrera].codigo, carreras[_codCarrera].nombre, carreras[_codCarrera].estadoCarrera);
    }
    //Obtener los caballos que están inscritos en una carrera
    function getCaballosEnCarrera(uint _codCarrera) public 
    carreraExiste(_codCarrera)
    view returns(string memory){ 
        string memory respuesta = "Caballos en la carrera #";
        bool contiene = false;
        respuesta = string(abi.encodePacked(respuesta, uint2str(_codCarrera)));
        respuesta = string(abi.encodePacked(respuesta, ": "));
        for (uint i = 0; i < competencias[_codCarrera].length; i++){
            contiene = true;
            respuesta = string(abi.encodePacked(respuesta,uint2str(competencias[_codCarrera][i])));
            if (i != competencias[_codCarrera].length-1){
                respuesta = string(abi.encodePacked(respuesta," - "));
            }else{
                break;
            }
        }
        if (!contiene){
            respuesta = string(abi.encodePacked(respuesta,"La carrera ingresada no tiene caballos"));
        }
        return (respuesta);
    }
    //obtener el o los apostadores ganadores en una carrera junto con los montos ganados por cada uno
    function getApostadorGanador(uint _codCarrera) public 
    carreraExiste(_codCarrera)
    estadoAct(_codCarrera, Estado.Terminada)
    cantApostadores(_codCarrera)
    view returns(string memory){
        string memory respuesta = "Ganadores en la carrera #";
        bool contiene = false;
        respuesta = string(abi.encodePacked(respuesta, uint2str(_codCarrera)));
        respuesta = string(abi.encodePacked(respuesta, ": "));
        for (uint i = 0; i < apostadores[_codCarrera].length; i ++){
            uint dinero = carreras[_codCarrera].apuestas[apostadores[_codCarrera][i]].dineroTransferido;
            if (dinero != 0){
                contiene = true;
                respuesta = string(abi.encodePacked(respuesta, "Apostador #"));
                respuesta = string(abi.encodePacked(respuesta, uint2str(i)));
                respuesta = string(abi.encodePacked(respuesta, "-"));
                respuesta = string(abi.encodePacked(respuesta, "Gano: "));
                respuesta = string(abi.encodePacked(respuesta, uint2str(dinero)));
                respuesta = string(abi.encodePacked(respuesta, "  "));
                
            }   
        }     
        return (respuesta);
    }

    //función para consultar la direccón de un apostador según su índice en la lista del mapping apostadores
    function getAddressApostador(uint _indiceApostador, uint _codCarrera) public 
    carreraExiste(_codCarrera)
    cantApostadores(_codCarrera)
    view returns(address){
        return apostadores[_codCarrera][_indiceApostador];
    }
    //obtener el caballo ganador de una carrera
    function getCaballoGanador(uint _codCarrera) public 
    carreraExiste(_codCarrera)
    estadoAct(_codCarrera, Estado.Terminada)
    view returns(uint) {
        return (carreras[_codCarrera].caballoGanador);
    }
    //obtner el estado actual de una carrera
    function getEstadoCarrera(uint _codCarrera) public 
    carreraExiste(_codCarrera)
    view returns(string memory){ 
        if (carreras[_codCarrera].estadoCarrera == Estado.Creada){
            return ("Creada");
        }else if (carreras[_codCarrera].estadoCarrera == Estado.Registrada){
            return ("Registrada");
        }else{
            return ("Terminada");
        }
    }
    //función utilizada para realizar concatenación de strings
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}