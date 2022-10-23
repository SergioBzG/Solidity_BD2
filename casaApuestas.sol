pragma solidity ^0.6.0;

contract casaApuestas{
    address public anfitrion;
    enum Estado {Creada, Registrada, Terminada}
    uint public totalCarreras;
    event Printazo(uint valor);
    mapping(uint => Carrera) public carreras; //carreras existentes
    mapping(uint => Caballo) public caballos; //caballos existentes
    mapping(uint => uint[]) public competencias; //caballos registrados en una carrera determinada
    mapping(uint => address[]) public apostadores; //apostadores registrados en una carrera determinada

    struct Carrera{
        uint codigo;
        string nombre;
        Estado estadoCarrera;
        uint montoTotal; //monto total de las apuestas realizadas en la carrera
        uint numeroCaballos;
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

    modifier caballoExiste(uint _codCaballo){
        require(bytes(caballos[_codCaballo].nombre).length != 0, "El caballo ingresado no existe");
        _;
    }

    modifier carreraExiste(uint _codCarrera){
        require(bytes(carreras[_codCarrera].nombre).length != 0, "La carrera ingresada no existe");
        _;
    }

    modifier caballoRepetido(uint _codCaballo){
        require(bytes(caballos[_codCaballo].nombre).length == 0, "Ya existe un caballo con este código");
        _;
    }

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
    //se verifica que un caballo esté registrado en una carrera determinada
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

    function crearCarrera(uint _codigo, string memory _nombre) public 
    isAnfitrion
    carreraRepetida(_codigo){
        // mapping(address => Apuesta) storage apuestas;
        // apuestas[msg.sender] = Apuesta(3,3,true);
        // Carrera storage c;
        // c.codigo = _codigo;
        // c.nombre = _nombre;
        // c.estadoCarrera = Estado.Creada;
        // c.apuestas = apuestas;
        // carreras[_codigo] = c;
        //= new Caballo[](6);
        carreras[_codigo] = Carrera(_codigo, _nombre, Estado.Creada, 0, 0);
        totalCarreras += 1;
    }

    function registrarCaballo(uint _codigo, string memory _nombre) public 
    isAnfitrion
    caballoRepetido(_codigo){
        caballos[_codigo] = Caballo(_codigo, _nombre);
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

    function registrarCarrera(uint _codCarrera) public 
    isAnfitrion
    estadoAct(_codCarrera, Estado.Creada)
    carreraExiste(_codCarrera)
    tamanoMin(_codCarrera){
        carreras[_codCarrera].estadoCarrera = Estado.Registrada;
    }

    function apostar(uint _codCaballo, uint _codCarrera) payable public 
    isNotAnfitrion
    estadoAct(_codCarrera, Estado.Registrada)
    caballoEnCarrera(_codCarrera, _codCaballo){
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
            carreras[_codCarrera].apuestas[apostador] = Apuesta(montoApuesta, _codCaballo, true, 0);
            carreras[_codCarrera].montoTotal += montoApuesta;
            apostadores[_codCarrera].push(apostador); // Apostadores por cada carrera
        }
    }

    function generarAleatorio(uint modulo) internal returns(uint){
        uint randNonce = 0;
        randNonce ++; 
        uint numero = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % modulo;
        return (numero);
    }

    function terminarCarrera(uint _codCarrera) payable public
    isAnfitrion
    carreraExiste(_codCarrera)
    estadoAct(_codCarrera, Estado.Registrada){
        uint indiceCaballoGanador = generarAleatorio(carreras[_codCarrera].numeroCaballos);  // Se obtiene le indice del caballo ganador (0,N-1)
        uint apostadoPorGanadores = 0; // El monto que apostaron unicamente los que ganaron (caballo ganador)

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
                }
            } 
            msg.sender.transfer(carreras[_codCarrera].montoTotal / 4);
        }else{
            msg.sender.transfer(carreras[_codCarrera].montoTotal);
        }
    }

    //function getApuestas(uint _codCarrera) public view returns(uint, uint) {
    //    return (carreras[_codCarrera].apuestas[msg.sender].monto, carreras[_codCarrera].apuestas[msg.sender].codCaballo);
    //}

    // function getCaballosEnCarrera(uint _codCarrera) public view returns(uint []) {
    //     //Retornar el array con los códigos de los caballos que pertenecen a la carrera 
    // }
}
