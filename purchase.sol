pragma solidity ^0.6.5;

contract Ownable {
    address public _owner;

    constructor () internal {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return (msg.sender == _owner);
    }
}

contract Item {
    uint public priceInWei;
    uint public paidWei;
    uint public index;
    uint public Qty;

    Purchase parentContract;

    constructor(Purchase _parentContract, uint _priceInWei, uint _index) public {
        priceInWei = _priceInWei;
        index = _index;
        parentContract = _parentContract;
        
    }
    /*receive() external payable {
        require(msg.value == priceInWei, "We don't support partial payments");
        require(paidWei == 0, "Item is already paid!");
        paidWei += msg.value;
        (bool success, )= address(parentContract).call{value:msg.value}(abi.encodeWithSignature("Payment(uint256)", index));
        require(success, "Delivery did not work");
    }*/
    fallback () external {
    }
}

contract Purchase is Ownable {
    struct S_Item {
        Item _item;
        Purchase.ActivityMasks _step;
        string _identifier; 
        uint _Qty;     
        uint _price;  
    }

    mapping(uint => S_Item) public items;
    uint index;

    enum ActivityMasks {Created, Paid, Delivered}

    event SupplyChainStep(uint _itemIndex, uint _step, address _address);

    function PurchaseOrder(string memory _identifier, uint _priceInWei, uint _Qty) public {
        Item item = new Item(this, _priceInWei, index);
        items[index]._item = item;
        items[index]._step = ActivityMasks.Created;
        items[index]._identifier = _identifier;
        items[index]._Qty = _Qty;
        items[index]._price = _priceInWei;
        
        emit SupplyChainStep(index, uint(items[index]._step), address(item));
        index++;
    }

    function Payment(uint _index) public payable {
        /*Item item = items[_index]._item;*/
        require(items[_index]._step == ActivityMasks.Delivered, "Incorrect item status");
        /*require(address(item) == msg.sender, "Only items are allowed to update themselves");*/
        require(items[_index]._price ==  msg.value, "Pay in exact amount");
        /*require(_price == msg.value, "Pay in exact amount");*/
        items[_index]._step = ActivityMasks.Paid;
        /*emit SupplyChainStep(_index, uint(items[_index]._step), address(items[_index]._item));*/
    }

    function Delivery(uint _index, uint _Qty) public onlyOwner {
        require(items[_index]._step == ActivityMasks.Created, "Incorrect item status");
        require(items[_index]._Qty == _Qty, "Incorrect Qty");
        items[_index]._step = ActivityMasks.Delivered;
        emit SupplyChainStep(_index, uint(items[_index]._step), address(items[_index]._item));
    }
}