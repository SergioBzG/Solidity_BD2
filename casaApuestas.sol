pragma solidity ^0.6.0;

contract casaApuestas{
    address payable public anfitrion;
    enum Estado {Creada, Registrada, Terminada}
    uint public totalCarreras;
    mapping(uint => Carrera) public carreras; //carreras existentes
    mapping(uint => Caballo) public caballos; //caballos existentes
    mapping(uint => uint[]) public competencias; 

    struct Carrera{
        uint codigo;
        string nombre;
        Estado estadoCarrera;
        mapping(address => Apuesta) apuestas;
    }

    struct Caballo{
        uint codigo;
        string nombre;
    }

    struct Apuesta{
        uint monto;
        uint codCaballo;
        bool creada;
    }

    constructor() public{
        anfitrion = msg.sender;
    }

    modifier isAnfitrion(){
        require(msg.sender == anfitrion, "El invocador debe ser el anfitrion");
        _;
    }

    modifier isNotAnfitrion(){
        require(msg.sender != anfitrion, "El invocador debe ser un usuario diferente al anfitrion");
        _;
    }

    modifier estadoAct(uint _codCarrera, Estado _estado){
        require(carreras[_codCarrera].estadoCarrera == _estado, "La carrera no cumple con el estado requerido");
        _;
    }
    
    modifier tamanoMax(uint _codCarrera){
        require(competencias[_codCarrera].length < 5, "La carrera ya cuenta con 5 caballos");
        _;
    }

    modifier tamanoMin(uint _codCarrera){
        require(competencias[_codCarrera].length >= 2, "La carrera debe contar con al menos 2 caballos");
        _;
    }

    modifier caballoExiste(uint _codCaballo){
        require(bytes(caballos[_codCaballo].nombre).length != 0, "El caballo ingresado no existe");
        _;
    }

    modifier carreraExiste(uint _codCarrera){
        require(bytes(caballos[_codCarrera].nombre).length != 0, "La carrera ingresada no existe");
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
        carreras[_codigo] = Carrera(_codigo, _nombre, Estado.Creada);
        totalCarreras += 1;
    }

    function registrarCaballo(uint _codigo, string memory _nombre) public 
    isAnfitrion
    caballoRepetido(_codigo){
        caballos[_codigo] = Caballo(_codigo, _nombre);
    }

    function registrarEnCarrera(uint _codCaballo, uint _codCarrera) public 
    isAnfitrion
    estadoAct(_codCarrera, Estado.Creada)
    tamanoMax(_codCarrera)
    caballoExiste(_codCaballo)
    carreraExiste(_codCarrera)
    caballoRepCarrera(_codCarrera, _codCaballo){
        competencias[_codCarrera].push(_codCaballo);
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
        } else{
            //Si el usuario no tiene apuestas previas se le crea una por primera vez
            carreras[_codCarrera].apuestas[apostador] = Apuesta(montoApuesta, _codCaballo, true);
        }
    }
}


//!!!!!!!!!!NO ESTÁ GUARDANDO EL MAPPING DE APUESTAS