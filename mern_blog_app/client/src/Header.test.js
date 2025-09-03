import { render, screen } from '@testing-library/react';
import Header from './componets/Header';
import configureStore from 'redux-mock-store';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';

const mockStore = configureStore([]);

function renderWithProviders(ui, { preloadedState } = {}) {
  const store = mockStore(
    preloadedState ?? {
      theme: { isDarkmode: false },
      auth: { isLoggedIn: false },
    },
  );
  return render(
    <Provider store={store}>
      <MemoryRouter>{ui}</MemoryRouter>
    </Provider>,
  );
}

test('muestra el título BlogsApp', () => {
  renderWithProviders(<Header />);
  expect(screen.getByText(/BlogsApp/i)).toBeInTheDocument();
});

test('muestra botones Login y SignUp cuando no hay sesión', () => {
  renderWithProviders(<Header />, {
    preloadedState: {
      theme: { isDarkmode: false },
      auth: { isLoggedIn: false },
    },
  });
  expect(screen.getByText(/Login/i)).toBeInTheDocument();
  expect(screen.getByText(/SignUp/i)).toBeInTheDocument();
});
