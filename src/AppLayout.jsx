import { useState } from 'react';
import { collection, getDocs, query, limit, deleteDoc, doc } from 'firebase/firestore';
import { db } from '../firebaseConfig'; // Import Firestore database
import { useNavigate } from 'react-router-dom'; // Import useNavigate for redirection
import './App.css';

function AdminPanel() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [collectionName, setCollectionName] = useState(''); // Store collection name
  const navigate = useNavigate(); // Hook for navigation

  // Fetch data from Firestore collection
  const fetchData = async (collectionName) => {
    setLoading(true);
    setCollectionName(collectionName); // Store the collection name

    try {
      const q = query(collection(db, collectionName), limit(100)); // Adjust the limit if needed
      const querySnapshot = await getDocs(q);
      
      // Map Firestore data to an array of objects
      const fetchedData = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      setData(fetchedData); // Update state with the fetched data
    } catch (error) {
      console.error('Error fetching data:', error);
    }
    setLoading(false);
  };

  // Delete item from Firestore and update local state
  const handleDelete = async (id) => {
    try {
      // Delete the document from Firestore
      await deleteDoc(doc(db, collectionName, id));
      
      // Remove the item from the local state
      setData(data.filter(item => item.id !== id));
    } catch (error) {
      console.error('Error deleting document:', error);
    }
  };

  // Logout handler
  const handleLogout = () => {
    // Clear any authentication data from localStorage or sessionStorage
    localStorage.removeItem('isAuthenticated');
    // Redirect to login page
    navigate('/');
  };

  // Define table headers based on collection name
  const getTableHeaders = () => {
    switch (collectionName) {
      case 'users':
        return ['ID', 'Email', 'Created At', 'Phone', 'Name', 'Actions'];
      case 'bookedride':
        return [
          'ID',
          'Passenger Name',
          'Passenger Email',
          'Destination',
          'Destination Name',
          'Driver Name',
          'Departure Time',
          'Is Ride Started',
          'Passenger Phone',
          'Actions'
        ];
      case 'enlistedrides':
        return [
          'ID',
          'Departure Time',
          'Destination',
          'Driver Name',
          'Driver Number',
          'Start Location Name',
          'Start Location',
          'Destination Name',
          'Actions'
        ];
      default:
        return [];
    }
  };

  // Define row data mapping based on collection name
  const getRowData = (item) => {
    switch (collectionName) {
      case 'users':
        return [item.id, item.email, item.createdAt, item.phone, item.name];
      case 'bookedride':
        return [
          item.id,
          item.passengerName,
          item.passengerEmail,
          item.destination,
          item.destinationName,
          item.driverName,
          item.departureTime,
          item.isRideStarted ? 'Yes' : 'No',
          item.passengerPhone,
        ];
      case 'enlistedrides':
        return [
          item.id,
          item.departureTime,
          item.destination,
          item.driverName,
          item.driverNumber,
          item.startLocationName,
          item.startLocation,
          item.destinationName,
        ];
      default:
        return [];
    }
  };

  return (
    <div className="flex h-screen">
      {/* Action Bar */}
      <div className="absolute top-0 left-0 w-80 h-full bg-gray-800 text-white flex flex-col items-start py-4 px-2 space-y-4">
        <h2 className="text-2xl font-semibold px-2">Carpool Admin Panel</h2>
        <button
          className="w-full text-left px-4 py-2 hover:bg-gray-700 rounded"
          onClick={() => fetchData('users')} // Fetch users data
        >
          Users
        </button>
        <button
          className="w-full text-left px-4 py-2 hover:bg-gray-700 rounded"
          onClick={() => fetchData('bookedride')} // Fetch booked rides data
        >
          Booked Rides
        </button>
        <button
          className="w-full text-left px-4 py-2 hover:bg-gray-700 rounded"
          onClick={() => fetchData('enlistedrides')} // Fetch enlisted rides data
        >
          Enlisted Rides
        </button>
        {/* Logout Button at the bottom of the action bar */}
        <button
          className="w-1/2 absolute bottom-5 left-16 text-center px-4 py-2 mt-auto hover:bg-red-700 rounded text-red-500"
          onClick={handleLogout}
        >
          Logout
        </button>
      </div>

      {/* Main Content */}
      <div className="ml-80 p-4 flex-1">
        <h1 className="text-2xl font-bold mb-4">Data Viewer</h1>
        {loading ? (
          <p>Loading...</p>
        ) : (
          <table className="min-w-full table-auto">
            <thead>
              <tr>
                {/* Dynamically generate table headers */}
                {getTableHeaders().map((header, index) => (
                  <th
                    key={index}
                    className="px-4 py-2 border-b-2 border-gray-300 text-left"
                  >
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {/* Render rows based on fetched data */}
              {data.map((item) => (
                <tr key={item.id}>
                  {getRowData(item).map((value, idx) => (
                    <td
                      key={idx}
                      className="px-4 py-2 border-b border-gray-200"
                    >
                      {String(value)}
                    </td>
                  ))}
                  <td className="px-4 py-2 border-b border-gray-200">
                    <button
                      className="text-red-600 hover:text-red-800"
                      onClick={() => handleDelete(item.id)}
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

export default AdminPanel;
