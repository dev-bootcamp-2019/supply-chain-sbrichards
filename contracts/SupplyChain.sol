pragma solidity ^0.5.0;

contract SupplyChain {
    address owner;
    uint skuCount;
    mapping (uint => Item) items;

    enum State {      
        ForSale,
        Sold,
        Shipped,
        Received
    }

    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
    }

    event ForSale(uint sku);
    event Sold(uint sku);
    event Shipped(uint sku);
    event Received(uint sku);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not the owner."); 
        _;
    }
    modifier verifyCaller(address _address) {
        require (msg.sender == _address, "Caller does not match.");
        _;
    }
    modifier paidEnough(uint _price) {
        require(msg.value >= _price, "Insuffienct funds.");
        _;
    }
    modifier checkValue(uint _sku) {
       //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint _price = items[_sku].price;
        uint amountToRefund = msg.value - _price;
        items[_sku].buyer.transfer(amountToRefund);
    }

    modifier forSale(uint sku) {
        require(items[sku].state == State.ForSale, "Item is not for sale.");
        _;
    }
    modifier sold(uint sku) {
        require(items[sku].state == State.Sold, "Item has not been sold.");
        _;
    }
    modifier shipped(uint sku) {
        require(items[sku].state == State.Shipped, "Item has not been shipped.");
        _;
    }
    modifier received(uint sku) {
        require(items[sku].state == State.Received, "Item has not been received.");
        _;
    }


    constructor() public {
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string memory _name, uint _price) public returns (bool) {
        emit ForSale(skuCount);
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });
        skuCount = skuCount + 1;
        return true;
    }

    function buyItem(uint sku)
        public
        payable
        forSale(sku)
        paidEnough(items[sku].price)
        checkValue(sku)
    {
        items[sku].seller.transfer(items[sku].price);
        items[sku].buyer = msg.sender;
        items[sku].state = State.Sold;
        emit Sold(sku);
    }

    function shipItem(uint sku)
        public
        sold(sku)
        verifyCaller(items[sku].seller)
    {
        items[sku].state = State.Shipped;
        emit Shipped(sku);
    }

    function receiveItem(uint sku)
        public
        shipped(sku)
        verifyCaller(items[sku].buyer)
    {
        items[sku].state = State.Received;
        emit Received(sku);
    }

    /* We have these functions completed so we can run tests, just ignore it :) */
    function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }

}
