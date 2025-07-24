// Test script to verify Django backend response format
// Run this in the browser console or as a separate test

const testBackendAPI = async () => {
    try {
        // Test 1: Login first (you need to replace with actual credentials)
        console.log('Testing Django backend API...');
        
        const loginResponse = await fetch('http://localhost:8000/user/login/', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                username: 'your_username', // Replace with actual username
                password: 'your_password'   // Replace with actual password
            })
        });
        
        if (loginResponse.ok) {
            const loginData = await loginResponse.json();
            console.log('Login successful:', loginData);
            
            const token = loginData.access;
            
            // Test 2: Fetch locations with token
            const locationsResponse = await fetch('http://localhost:8000/user/locations/', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                }
            });
            
            if (locationsResponse.ok) {
                const locationsData = await locationsResponse.json();
                console.log('Locations API Response:', locationsData);
                console.log('Response structure:');
                console.log('- message:', locationsData.message);
                console.log('- data:', locationsData.data);
                console.log('- locations count:', locationsData.data?.locations?.length || 0);
                
                if (locationsData.data?.locations?.length > 0) {
                    console.log('First location sample:', locationsData.data.locations[0]);
                }
            } else {
                console.error('Locations API failed:', locationsResponse.status, await locationsResponse.text());
            }
        } else {
            console.error('Login failed:', loginResponse.status, await loginResponse.text());
        }
    } catch (error) {
        console.error('Test failed:', error);
    }
};

// Uncomment the line below to run the test
// testBackendAPI();
